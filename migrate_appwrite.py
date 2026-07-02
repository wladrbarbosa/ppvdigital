import urllib.request
import urllib.error
import urllib.parse
import json
import time
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Source Instance (Appwrite Cloud)
SOURCE_ENDPOINT = "https://cloud.appwrite.io/v1"
SOURCE_PROJECT_ID = "671f6df50033227ea6d6"
SOURCE_API_KEY = "YOUR_SOURCE_API_KEY"

# Destination Instance (Self-Hosted)
DEST_ENDPOINT = "http://localhost/v1"  # Replace with your self-hosted endpoint
DEST_PROJECT_ID = "671f6df50033227ea6d6" # Replace with your destination project ID
DEST_API_KEY = "YOUR_DEST_API_KEY"

# Migration Batch & Parallelization Settings
SOURCE_BATCH_LIMIT = 1000  # Number of documents to fetch per page from Appwrite Cloud (100 for free plan, up to 1000 for paid plans)
MAX_WORKERS = 15           # Number of concurrent worker threads for writing documents
# ==============================================================================

def make_request(endpoint, headers, path, method="GET", body=None, max_retries=5, backoff_factor=2):
    url = f"{endpoint}{path}"
    data = None
    if body is not None:
        data = json.dumps(body).encode('utf-8')
    
    retries = 0
    while True:
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=45) as response:
                return json.loads(response.read().decode('utf-8'))
        except urllib.error.HTTPError as e:
            if e.code in (500, 502, 503, 504) and retries < max_retries:
                sleep_time = backoff_factor ** retries
                print(f"  [Warning] HTTP {e.code} on {path}. Retrying in {sleep_time}s... ({retries + 1}/{max_retries})")
                time.sleep(sleep_time)
                retries += 1
                continue
                
            err_body = e.read().decode('utf-8')
            try:
                err_json = json.loads(err_body)
                message = err_json.get("message", err_body)
            except Exception:
                message = err_body
            raise Exception(f"HTTP {e.code}: {message}")
        except Exception as e:
            if retries < max_retries:
                sleep_time = backoff_factor ** retries
                print(f"  [Warning] Connection/Request error: {e}. Retrying in {sleep_time}s... ({retries + 1}/{max_retries})")
                time.sleep(sleep_time)
                retries += 1
                continue
            raise e

def wait_for_attributes(endpoint, headers, database_id, collection_id, timeout_sec=90):
    print(f"Waiting for attributes in collection {collection_id} to build...")
    start_time = time.time()
    while True:
        res = make_request(endpoint, headers, f"/databases/{database_id}/collections/{collection_id}/attributes")
        pending = [a for a in res['attributes'] if a['status'] not in ('available', 'failed')]
        if not pending:
            break
            
        elapsed = time.time() - start_time
        if elapsed > timeout_sec:
            print(f"  [Warning] Timeout reached while waiting for attributes to build in collection {collection_id}!")
            for a in pending:
                print(f"    - Attribute '{a['key']}' is stuck in status: '{a['status']}'")
            print("  Please verify if your self-hosted Appwrite database worker container ('appwrite-worker-databases') is running and healthy.")
            break
            
        pending_details = ", ".join([f"'{a['key']}' ({a['status']})" for a in pending])
        print(f"  - Still building: {pending_details} (elapsed: {int(elapsed)}s)")
        time.sleep(3)

def clean_document_data(data, attributes, exclude_relationships=False):
    cleaned = {}
    for attr in attributes:
        key = attr['key']
        if key not in data:
            continue
        val = data[key]
        if val is None:
            cleaned[key] = None
            continue
        
        if attr.get('type') == 'relationship':
            if exclude_relationships:
                continue
            if attr.get('array', False):
                if isinstance(val, list):
                    cleaned[key] = [item['$id'] if isinstance(item, dict) and '$id' in item else item for item in val]
                else:
                    cleaned[key] = []
            else:
                if isinstance(val, dict) and '$id' in val:
                    cleaned[key] = val['$id']
                else:
                    cleaned[key] = val
        else:
            if key.startswith('$'):
                continue
            cleaned[key] = val
    return cleaned

def get_relationship_data(data, attributes):
    cleaned = {}
    has_relationships = False
    for attr in attributes:
        if attr.get('type') == 'relationship':
            key = attr['key']
            if key not in data:
                continue
            val = data[key]
            if val is None:
                cleaned[key] = None
                has_relationships = True
                continue
            
            has_relationships = True
            if attr.get('array', False):
                if isinstance(val, list):
                    cleaned[key] = [item['$id'] if isinstance(item, dict) and '$id' in item else item for item in val]
                else:
                    cleaned[key] = []
            else:
                if isinstance(val, dict) and '$id' in val:
                    cleaned[key] = val['$id']
                else:
                    cleaned[key] = val
    return cleaned, has_relationships

def update_document_relationships(endpoint, headers, database_id, collection_id, doc_id, relationship_data):
    try:
        make_request(
            endpoint, 
            headers, 
            f"/databases/{database_id}/collections/{collection_id}/documents/{doc_id}", 
            "PATCH", 
            {
                "data": relationship_data
            }
        )
        return True
    except Exception as e:
        print(f"  ! Error updating relationships for document {doc_id}: {e}")
        return False

def migrate_single_document(endpoint, headers, database_id, collection_id, doc_id, cleaned_data, permissions):
    try:
        make_request(
            endpoint, 
            headers, 
            f"/databases/{database_id}/collections/{collection_id}/documents", 
            "POST", 
            {
                "documentId": doc_id,
                "data": cleaned_data,
                "permissions": permissions
            }
        )
        return True
    except Exception as e:
        if "already exists" in str(e).lower() or "HTTP 409" in str(e):
            try:
                make_request(
                    endpoint, 
                    headers, 
                    f"/databases/{database_id}/collections/{collection_id}/documents/{doc_id}", 
                    "PATCH", 
                    {
                        "data": cleaned_data,
                        "permissions": permissions
                    }
                )
                return True
            except Exception as update_err:
                print(f"  ! Error updating existing document {doc_id}: {update_err}")
                return False
        else:
            print(f"  ! Error creating document {doc_id}: {e}")
            return False



def migrate():
    # Setup headers
    src_headers = {
        "X-Appwrite-Project": SOURCE_PROJECT_ID,
        "X-Appwrite-Key": SOURCE_API_KEY,
        "Content-Type": "application/json"
    }
    
    dest_headers = {
        "X-Appwrite-Project": DEST_PROJECT_ID,
        "X-Appwrite-Key": DEST_API_KEY,
        "Content-Type": "application/json"
    }

    if SOURCE_API_KEY == "YOUR_SOURCE_API_KEY" or DEST_API_KEY == "YOUR_DEST_API_KEY":
        print("ERROR: Please replace YOUR_SOURCE_API_KEY and YOUR_DEST_API_KEY with actual keys in the script.")
        sys.exit(1)

    print("=== STARTING APPWRITE DATABASE MIGRATION ===")
    
    # 1. Get all databases from source
    print("\nFetching databases from source...")
    dbs = make_request(SOURCE_ENDPOINT, src_headers, "/databases")
    print(f"Found {len(dbs['databases'])} database(s) in source.")

    for db in dbs['databases']:
        db_id = db['$id']
        db_name = db['name']
        print(f"\n--- Migrating Database: {db_name} (ID: {db_id}) ---")

        # Create Database in Destination
        try:
            make_request(DEST_ENDPOINT, dest_headers, "/databases", "POST", {
                "databaseId": db_id,
                "name": db_name
            })
            print(f"Created database '{db_name}' in destination.")
        except Exception as e:
            if "already exists" in str(e).lower() or "HTTP 409" in str(e):
                print(f"Database '{db_name}' already exists in destination. Skipping creation.")
            else:
                print(f"Error creating database: {e}")
                continue

        # Get Collections from source
        collections_res = make_request(SOURCE_ENDPOINT, src_headers, f"/databases/{db_id}/collections")
        collections = collections_res['collections']
        print(f"Found {len(collections)} collections in database '{db_name}'.")

        # Step A: Create Collections in Destination
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            try:
                make_request(DEST_ENDPOINT, dest_headers, f"/databases/{db_id}/collections", "POST", {
                    "collectionId": col_id,
                    "name": col_name,
                    "permissions": col.get("permissions", []),
                    "documentSecurity": col.get("documentSecurity", False)
                })
                print(f"  + Created collection '{col_name}' (ID: {col_id})")
            except Exception as e:
                if "already exists" in str(e).lower() or "HTTP 409" in str(e):
                    print(f"  * Collection '{col_name}' already exists. Skipping creation.")
                else:
                    print(f"  ! Error creating collection '{col_name}': {e}")

        # Step B: Create standard attributes in Destination
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            print(f"\nMigrating attributes for collection '{col_name}'...")
            attr_res = make_request(SOURCE_ENDPOINT, src_headers, f"/databases/{db_id}/collections/{col_id}/attributes")
            
            for attr in attr_res['attributes']:
                key = attr['key']
                attr_type = attr.get('type')
                
                # Skip relationships on this step
                if attr_type == 'relationship':
                    continue
                
                # Construct creation payload
                payload = {
                    "key": key,
                    "required": attr.get("required", False),
                    "array": attr.get("array", False),
                    "default": attr.get("default")
                }
                
                # Appwrite API requires custom path per type
                path_suffix = attr_type
                if attr_type in ('varchar', 'string'):
                    path_suffix = 'string'
                elif attr_type == 'double':
                    path_suffix = 'float'
                
                # Check for special string formats
                format_type = attr.get('format', '')
                if path_suffix == 'string' and format_type in ('email', 'ip', 'url'):
                    path_suffix = format_type
                
                if path_suffix == 'string':
                    size = attr.get("size")
                    payload["size"] = int(size) if (size is not None and size != 0) else 255
                elif path_suffix in ('integer', 'float'):
                    payload["min"] = attr.get("min")
                    payload["max"] = attr.get("max")
                elif path_suffix == 'enum':
                    payload["elements"] = attr.get("elements", [])
                
                try:
                    make_request(
                        DEST_ENDPOINT, 
                        dest_headers, 
                        f"/databases/{db_id}/collections/{col_id}/attributes/{path_suffix}", 
                        "POST", 
                        payload
                    )
                    print(f"  + Created attribute '{key}' ({attr_type})")
                except Exception as e:
                    if "already exists" in str(e).lower() or "HTTP 409" in str(e):
                        pass
                    else:
                        print(f"  ! Error creating attribute '{key}': {e}")
            
            # Wait for standard attributes to build
            wait_for_attributes(DEST_ENDPOINT, dest_headers, db_id, col_id)

        # Step C: Create relationship attributes in Destination
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            attr_res = make_request(SOURCE_ENDPOINT, src_headers, f"/databases/{db_id}/collections/{col_id}/attributes")
            
            for attr in attr_res['attributes']:
                if attr.get('type') != 'relationship':
                    continue
                
                # Relationships are created from parent side only to avoid duplicates
                if attr.get('side') != 'parent':
                    continue
                
                key = attr['key']
                payload = {
                    "relatedCollectionId": attr.get("relatedCollection"),
                    "type": attr.get("relationType"),
                    "twoWay": attr.get("twoWay", False),
                    "key": key,
                    "twoWayKey": attr.get("twoWayKey"),
                    "onDelete": attr.get("onDelete", "setNull")
                }
                
                try:
                    make_request(
                        DEST_ENDPOINT, 
                        dest_headers, 
                        f"/databases/{db_id}/collections/{col_id}/attributes/relationship", 
                        "POST", 
                        payload
                    )
                    print(f"  + Created relationship attribute '{key}' (Type: {attr.get('relationType')})")
                except Exception as e:
                    if "already exists" in str(e).lower() or "HTTP 409" in str(e):
                        pass
                    else:
                        print(f"  ! Error creating relationship '{key}': {e}")
            
            # Wait for relationship attributes to build
            wait_for_attributes(DEST_ENDPOINT, dest_headers, db_id, col_id)

        # Step D: Create Indexes in Destination
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            print(f"\nMigrating indexes for collection '{col_name}'...")
            idx_res = make_request(SOURCE_ENDPOINT, src_headers, f"/databases/{db_id}/collections/{col_id}/indexes")
            
            for idx in idx_res['indexes']:
                key = idx['key']
                if key.startswith('$'): # Skip system indexes
                    continue
                
                payload = {
                    "key": key,
                    "type": idx['type'],
                    "attributes": idx['attributes'],
                    "orders": idx.get('orders', []),
                    "lengths": idx.get('lengths', [])
                }
                
                try:
                    make_request(
                        DEST_ENDPOINT, 
                        dest_headers, 
                        f"/databases/{db_id}/collections/{col_id}/indexes", 
                        "POST", 
                        payload
                    )
                    print(f"  + Created index '{key}'")
                except Exception as e:
                    if "already exists" in str(e).lower() or "HTTP 409" in str(e):
                        pass
                    else:
                        print(f"  ! Error creating index '{key}': {e}")

        # Step E: Migrate Documents in Destination
        # Dynamically scan and map hidden one-way relationship attributes
        hidden_relationships = {}
        print("\nScanning for hidden relationship attributes in destination...")
        for col in collections:
            col_id = col['$id']
            dest_attr_res = make_request(DEST_ENDPOINT, dest_headers, f"/databases/{db_id}/collections/{col_id}/attributes")
            for attr in dest_attr_res['attributes']:
                if (attr.get('type') == 'relationship' and 
                    attr.get('relationType') == 'oneToMany' and 
                    not attr.get('twoWay', False)):
                    
                    related_col = attr.get('relatedCollection')
                    two_way_key = attr.get('twoWayKey')
                    if related_col and two_way_key:
                        if related_col not in hidden_relationships:
                            hidden_relationships[related_col] = []
                        hidden_relationships[related_col].append({
                            'key': two_way_key,
                            'type': 'relationship',
                            'array': False
                        })
                        print(f"  * Detected hidden relationship: {col_id} -> {related_col} via key '{two_way_key}'")

        # Pass 1: Create all documents excluding relationship fields
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            print(f"\nMigrating documents for collection '{col_name}' (Pass 1: Creating documents)...")
            
            # Fetch attributes schema from destination to clean relationship values
            dest_attr_res = make_request(DEST_ENDPOINT, dest_headers, f"/databases/{db_id}/collections/{col_id}/attributes")
            dest_attributes = dest_attr_res['attributes']
            if col_id in hidden_relationships:
                dest_attributes.extend(hidden_relationships[col_id])
            
            # Paginate documents fetching from source using cursorAfter
            last_id = None
            total_migrated = 0
            chunk_size = SOURCE_BATCH_LIMIT  # Strict Appwrite Cloud API limit
            
            while True:
                queries = [
                    json.dumps({"method": "limit", "values": [chunk_size]})
                ]
                if last_id is not None:
                    queries.append(
                        json.dumps({"method": "cursorAfter", "values": [last_id]})
                    )
                
                query_params = [('queries[]', q) for q in queries]
                query_str = urllib.parse.urlencode(query_params)
                
                docs_res = make_request(
                    SOURCE_ENDPOINT, 
                    src_headers, 
                    f"/databases/{db_id}/collections/{col_id}/documents?{query_str}"
                )
                documents = docs_res.get('documents', [])
                if not documents:
                    break
                
                with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
                    futures = []
                    for doc in documents:
                        doc_id = doc['$id']
                        cleaned_data = clean_document_data(doc, dest_attributes, exclude_relationships=True)
                        futures.append(executor.submit(
                            migrate_single_document,
                            DEST_ENDPOINT,
                            dest_headers,
                            db_id,
                            col_id,
                            doc_id,
                            cleaned_data,
                            doc.get("$permissions", [])
                        ))
                    
                    for future in as_completed(futures):
                        if future.result():
                            total_migrated += 1
                
                last_id = documents[-1]['$id']
                print(f"  - Progress: created {total_migrated} documents so far...")
                
                if len(documents) < chunk_size:
                    break
            
            print(f"Completed Pass 1 for collection '{col_name}'. Created {total_migrated} documents.")

        # Pass 2: Update relationship fields for all documents
        for col in collections:
            col_id = col['$id']
            col_name = col['name']
            
            # Fetch attributes schema from destination
            dest_attr_res = make_request(DEST_ENDPOINT, dest_headers, f"/databases/{db_id}/collections/{col_id}/attributes")
            dest_attributes = dest_attr_res['attributes']
            if col_id in hidden_relationships:
                dest_attributes.extend(hidden_relationships[col_id])
            
            # Check if there are any relationship attributes
            has_any_rel = any(a.get('type') == 'relationship' for a in dest_attributes)
            if not has_any_rel:
                print(f"\nSkipping Pass 2 for collection '{col_name}' (No relationship attributes).")
                continue
                
            print(f"\nUpdating document relationships for collection '{col_name}' (Pass 2)...")
            
            last_id = None
            total_updated = 0
            chunk_size = SOURCE_BATCH_LIMIT
            
            while True:
                queries = [
                    json.dumps({"method": "limit", "values": [chunk_size]})
                ]
                if last_id is not None:
                    queries.append(
                        json.dumps({"method": "cursorAfter", "values": [last_id]})
                    )
                
                query_params = [('queries[]', q) for q in queries]
                query_str = urllib.parse.urlencode(query_params)
                
                docs_res = make_request(
                    SOURCE_ENDPOINT, 
                    src_headers, 
                    f"/databases/{db_id}/collections/{col_id}/documents?{query_str}"
                )
                documents = docs_res.get('documents', [])
                if not documents:
                    break
                
                with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
                    futures = []
                    for doc in documents:
                        doc_id = doc['$id']
                        rel_data, has_rel = get_relationship_data(doc, dest_attributes)
                        if has_rel:
                            futures.append(executor.submit(
                                update_document_relationships,
                                DEST_ENDPOINT,
                                dest_headers,
                                db_id,
                                col_id,
                                doc_id,
                                rel_data
                            ))
                    
                    for future in as_completed(futures):
                        if future.result():
                            total_updated += 1
                
                last_id = documents[-1]['$id']
                print(f"  - Progress: updated relationships for {total_updated} documents so far...")
                
                if len(documents) < chunk_size:
                    break
            
            print(f"Completed Pass 2 for collection '{col_name}'. Updated relationships for {total_updated} documents.")

    print("\n=== MIGRATION COMPLETED SUCCESSFULLY ===")

if __name__ == "__main__":
    migrate()
