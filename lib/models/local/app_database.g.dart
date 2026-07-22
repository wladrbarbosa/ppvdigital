// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String key;
  final String value;
  const AppSetting({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({int? id, String? key, String? value}) => AppSetting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String>? value,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $TarefaHabitosTable extends TarefaHabitos
    with TableInfo<$TarefaHabitosTable, TarefaHabito> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TarefaHabitosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioMeta = const VerificationMeta(
    'usuario',
  );
  @override
  late final GeneratedColumn<String> usuario = GeneratedColumn<String>(
    'usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _concluidaMeta = const VerificationMeta(
    'concluida',
  );
  @override
  late final GeneratedColumn<bool> concluida = GeneratedColumn<bool>(
    'concluida',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("concluida" IN (0, 1))',
    ),
  );
  static const VerificationMeta _agendamentoMeta = const VerificationMeta(
    'agendamento',
  );
  @override
  late final GeneratedColumn<DateTime> agendamento = GeneratedColumn<DateTime>(
    'agendamento',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<TarefaHabitoQtdModel>,
    String
  >
  metas =
      GeneratedColumn<String>(
        'metas',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<TarefaHabitoQtdModel>>(
        $TarefaHabitosTable.$convertermetas,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    nome,
    tipo,
    usuario,
    concluida,
    agendamento,
    duration,
    metas,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tarefa_habitos';
  @override
  VerificationContext validateIntegrity(
    Insertable<TarefaHabito> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('usuario')) {
      context.handle(
        _usuarioMeta,
        usuario.isAcceptableOrUnknown(data['usuario']!, _usuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioMeta);
    }
    if (data.containsKey('concluida')) {
      context.handle(
        _concluidaMeta,
        concluida.isAcceptableOrUnknown(data['concluida']!, _concluidaMeta),
      );
    } else if (isInserting) {
      context.missing(_concluidaMeta);
    }
    if (data.containsKey('agendamento')) {
      context.handle(
        _agendamentoMeta,
        agendamento.isAcceptableOrUnknown(
          data['agendamento']!,
          _agendamentoMeta,
        ),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TarefaHabito map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TarefaHabito(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      usuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario'],
      )!,
      concluida: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}concluida'],
      )!,
      agendamento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}agendamento'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      metas: $TarefaHabitosTable.$convertermetas.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}metas'],
        )!,
      ),
    );
  }

  @override
  $TarefaHabitosTable createAlias(String alias) {
    return $TarefaHabitosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TarefaHabitoQtdModel>, String> $convertermetas =
      const MetasConverter();
}

class TarefaHabito extends DataClass implements Insertable<TarefaHabito> {
  final int id;
  final String remoteId;
  final String nome;
  final String tipo;
  final String usuario;
  final bool concluida;
  final DateTime? agendamento;
  final int? duration;
  final List<TarefaHabitoQtdModel> metas;
  const TarefaHabito({
    required this.id,
    required this.remoteId,
    required this.nome,
    required this.tipo,
    required this.usuario,
    required this.concluida,
    this.agendamento,
    this.duration,
    required this.metas,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['nome'] = Variable<String>(nome);
    map['tipo'] = Variable<String>(tipo);
    map['usuario'] = Variable<String>(usuario);
    map['concluida'] = Variable<bool>(concluida);
    if (!nullToAbsent || agendamento != null) {
      map['agendamento'] = Variable<DateTime>(agendamento);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    {
      map['metas'] = Variable<String>(
        $TarefaHabitosTable.$convertermetas.toSql(metas),
      );
    }
    return map;
  }

  TarefaHabitosCompanion toCompanion(bool nullToAbsent) {
    return TarefaHabitosCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      nome: Value(nome),
      tipo: Value(tipo),
      usuario: Value(usuario),
      concluida: Value(concluida),
      agendamento: agendamento == null && nullToAbsent
          ? const Value.absent()
          : Value(agendamento),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      metas: Value(metas),
    );
  }

  factory TarefaHabito.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TarefaHabito(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      nome: serializer.fromJson<String>(json['nome']),
      tipo: serializer.fromJson<String>(json['tipo']),
      usuario: serializer.fromJson<String>(json['usuario']),
      concluida: serializer.fromJson<bool>(json['concluida']),
      agendamento: serializer.fromJson<DateTime?>(json['agendamento']),
      duration: serializer.fromJson<int?>(json['duration']),
      metas: serializer.fromJson<List<TarefaHabitoQtdModel>>(json['metas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'nome': serializer.toJson<String>(nome),
      'tipo': serializer.toJson<String>(tipo),
      'usuario': serializer.toJson<String>(usuario),
      'concluida': serializer.toJson<bool>(concluida),
      'agendamento': serializer.toJson<DateTime?>(agendamento),
      'duration': serializer.toJson<int?>(duration),
      'metas': serializer.toJson<List<TarefaHabitoQtdModel>>(metas),
    };
  }

  TarefaHabito copyWith({
    int? id,
    String? remoteId,
    String? nome,
    String? tipo,
    String? usuario,
    bool? concluida,
    Value<DateTime?> agendamento = const Value.absent(),
    Value<int?> duration = const Value.absent(),
    List<TarefaHabitoQtdModel>? metas,
  }) => TarefaHabito(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    nome: nome ?? this.nome,
    tipo: tipo ?? this.tipo,
    usuario: usuario ?? this.usuario,
    concluida: concluida ?? this.concluida,
    agendamento: agendamento.present ? agendamento.value : this.agendamento,
    duration: duration.present ? duration.value : this.duration,
    metas: metas ?? this.metas,
  );
  TarefaHabito copyWithCompanion(TarefaHabitosCompanion data) {
    return TarefaHabito(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      nome: data.nome.present ? data.nome.value : this.nome,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      usuario: data.usuario.present ? data.usuario.value : this.usuario,
      concluida: data.concluida.present ? data.concluida.value : this.concluida,
      agendamento: data.agendamento.present
          ? data.agendamento.value
          : this.agendamento,
      duration: data.duration.present ? data.duration.value : this.duration,
      metas: data.metas.present ? data.metas.value : this.metas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TarefaHabito(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('usuario: $usuario, ')
          ..write('concluida: $concluida, ')
          ..write('agendamento: $agendamento, ')
          ..write('duration: $duration, ')
          ..write('metas: $metas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    nome,
    tipo,
    usuario,
    concluida,
    agendamento,
    duration,
    metas,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TarefaHabito &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.nome == this.nome &&
          other.tipo == this.tipo &&
          other.usuario == this.usuario &&
          other.concluida == this.concluida &&
          other.agendamento == this.agendamento &&
          other.duration == this.duration &&
          other.metas == this.metas);
}

class TarefaHabitosCompanion extends UpdateCompanion<TarefaHabito> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> nome;
  final Value<String> tipo;
  final Value<String> usuario;
  final Value<bool> concluida;
  final Value<DateTime?> agendamento;
  final Value<int?> duration;
  final Value<List<TarefaHabitoQtdModel>> metas;
  const TarefaHabitosCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.nome = const Value.absent(),
    this.tipo = const Value.absent(),
    this.usuario = const Value.absent(),
    this.concluida = const Value.absent(),
    this.agendamento = const Value.absent(),
    this.duration = const Value.absent(),
    this.metas = const Value.absent(),
  });
  TarefaHabitosCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String nome,
    required String tipo,
    required String usuario,
    required bool concluida,
    this.agendamento = const Value.absent(),
    this.duration = const Value.absent(),
    required List<TarefaHabitoQtdModel> metas,
  }) : remoteId = Value(remoteId),
       nome = Value(nome),
       tipo = Value(tipo),
       usuario = Value(usuario),
       concluida = Value(concluida),
       metas = Value(metas);
  static Insertable<TarefaHabito> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? nome,
    Expression<String>? tipo,
    Expression<String>? usuario,
    Expression<bool>? concluida,
    Expression<DateTime>? agendamento,
    Expression<int>? duration,
    Expression<String>? metas,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (nome != null) 'nome': nome,
      if (tipo != null) 'tipo': tipo,
      if (usuario != null) 'usuario': usuario,
      if (concluida != null) 'concluida': concluida,
      if (agendamento != null) 'agendamento': agendamento,
      if (duration != null) 'duration': duration,
      if (metas != null) 'metas': metas,
    });
  }

  TarefaHabitosCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? nome,
    Value<String>? tipo,
    Value<String>? usuario,
    Value<bool>? concluida,
    Value<DateTime?>? agendamento,
    Value<int?>? duration,
    Value<List<TarefaHabitoQtdModel>>? metas,
  }) {
    return TarefaHabitosCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      usuario: usuario ?? this.usuario,
      concluida: concluida ?? this.concluida,
      agendamento: agendamento ?? this.agendamento,
      duration: duration ?? this.duration,
      metas: metas ?? this.metas,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (usuario.present) {
      map['usuario'] = Variable<String>(usuario.value);
    }
    if (concluida.present) {
      map['concluida'] = Variable<bool>(concluida.value);
    }
    if (agendamento.present) {
      map['agendamento'] = Variable<DateTime>(agendamento.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (metas.present) {
      map['metas'] = Variable<String>(
        $TarefaHabitosTable.$convertermetas.toSql(metas.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TarefaHabitosCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('nome: $nome, ')
          ..write('tipo: $tipo, ')
          ..write('usuario: $usuario, ')
          ..write('concluida: $concluida, ')
          ..write('agendamento: $agendamento, ')
          ..write('duration: $duration, ')
          ..write('metas: $metas')
          ..write(')'))
        .toString();
  }
}

class $HistoricoTarefasHabitosTable extends HistoricoTarefasHabitos
    with TableInfo<$HistoricoTarefasHabitosTable, HistoricoTarefasHabito> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoricoTarefasHabitosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _usuarioMeta = const VerificationMeta(
    'usuario',
  );
  @override
  late final GeneratedColumn<String> usuario = GeneratedColumn<String>(
    'usuario',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tarefaHabitoIdMeta = const VerificationMeta(
    'tarefaHabitoId',
  );
  @override
  late final GeneratedColumn<String> tarefaHabitoId = GeneratedColumn<String>(
    'tarefa_habito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    usuario,
    tarefaHabitoId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'historico_tarefas_habitos';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoricoTarefasHabito> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('usuario')) {
      context.handle(
        _usuarioMeta,
        usuario.isAcceptableOrUnknown(data['usuario']!, _usuarioMeta),
      );
    } else if (isInserting) {
      context.missing(_usuarioMeta);
    }
    if (data.containsKey('tarefa_habito_id')) {
      context.handle(
        _tarefaHabitoIdMeta,
        tarefaHabitoId.isAcceptableOrUnknown(
          data['tarefa_habito_id']!,
          _tarefaHabitoIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tarefaHabitoIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoricoTarefasHabito map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoricoTarefasHabito(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      usuario: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario'],
      )!,
      tarefaHabitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tarefa_habito_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HistoricoTarefasHabitosTable createAlias(String alias) {
    return $HistoricoTarefasHabitosTable(attachedDatabase, alias);
  }
}

class HistoricoTarefasHabito extends DataClass
    implements Insertable<HistoricoTarefasHabito> {
  final int id;
  final String remoteId;
  final String usuario;
  final String tarefaHabitoId;
  final DateTime createdAt;
  const HistoricoTarefasHabito({
    required this.id,
    required this.remoteId,
    required this.usuario,
    required this.tarefaHabitoId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['usuario'] = Variable<String>(usuario);
    map['tarefa_habito_id'] = Variable<String>(tarefaHabitoId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HistoricoTarefasHabitosCompanion toCompanion(bool nullToAbsent) {
    return HistoricoTarefasHabitosCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      usuario: Value(usuario),
      tarefaHabitoId: Value(tarefaHabitoId),
      createdAt: Value(createdAt),
    );
  }

  factory HistoricoTarefasHabito.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoricoTarefasHabito(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      usuario: serializer.fromJson<String>(json['usuario']),
      tarefaHabitoId: serializer.fromJson<String>(json['tarefaHabitoId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'usuario': serializer.toJson<String>(usuario),
      'tarefaHabitoId': serializer.toJson<String>(tarefaHabitoId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  HistoricoTarefasHabito copyWith({
    int? id,
    String? remoteId,
    String? usuario,
    String? tarefaHabitoId,
    DateTime? createdAt,
  }) => HistoricoTarefasHabito(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    usuario: usuario ?? this.usuario,
    tarefaHabitoId: tarefaHabitoId ?? this.tarefaHabitoId,
    createdAt: createdAt ?? this.createdAt,
  );
  HistoricoTarefasHabito copyWithCompanion(
    HistoricoTarefasHabitosCompanion data,
  ) {
    return HistoricoTarefasHabito(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      usuario: data.usuario.present ? data.usuario.value : this.usuario,
      tarefaHabitoId: data.tarefaHabitoId.present
          ? data.tarefaHabitoId.value
          : this.tarefaHabitoId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoricoTarefasHabito(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('usuario: $usuario, ')
          ..write('tarefaHabitoId: $tarefaHabitoId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, remoteId, usuario, tarefaHabitoId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoricoTarefasHabito &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.usuario == this.usuario &&
          other.tarefaHabitoId == this.tarefaHabitoId &&
          other.createdAt == this.createdAt);
}

class HistoricoTarefasHabitosCompanion
    extends UpdateCompanion<HistoricoTarefasHabito> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> usuario;
  final Value<String> tarefaHabitoId;
  final Value<DateTime> createdAt;
  const HistoricoTarefasHabitosCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.usuario = const Value.absent(),
    this.tarefaHabitoId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HistoricoTarefasHabitosCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String usuario,
    required String tarefaHabitoId,
    required DateTime createdAt,
  }) : remoteId = Value(remoteId),
       usuario = Value(usuario),
       tarefaHabitoId = Value(tarefaHabitoId),
       createdAt = Value(createdAt);
  static Insertable<HistoricoTarefasHabito> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? usuario,
    Expression<String>? tarefaHabitoId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (usuario != null) 'usuario': usuario,
      if (tarefaHabitoId != null) 'tarefa_habito_id': tarefaHabitoId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HistoricoTarefasHabitosCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? usuario,
    Value<String>? tarefaHabitoId,
    Value<DateTime>? createdAt,
  }) {
    return HistoricoTarefasHabitosCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      usuario: usuario ?? this.usuario,
      tarefaHabitoId: tarefaHabitoId ?? this.tarefaHabitoId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (usuario.present) {
      map['usuario'] = Variable<String>(usuario.value);
    }
    if (tarefaHabitoId.present) {
      map['tarefa_habito_id'] = Variable<String>(tarefaHabitoId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoricoTarefasHabitosCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('usuario: $usuario, ')
          ..write('tarefaHabitoId: $tarefaHabitoId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ContasTable extends Contas with TableInfo<$ContasTable, Conta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saldoAtualMeta = const VerificationMeta(
    'saldoAtual',
  );
  @override
  late final GeneratedColumn<double> saldoAtual = GeneratedColumn<double>(
    'saldo_atual',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    name,
    userId,
    saldoAtual,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('saldo_atual')) {
      context.handle(
        _saldoAtualMeta,
        saldoAtual.isAcceptableOrUnknown(data['saldo_atual']!, _saldoAtualMeta),
      );
    } else if (isInserting) {
      context.missing(_saldoAtualMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Conta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conta(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      saldoAtual: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}saldo_atual'],
      )!,
    );
  }

  @override
  $ContasTable createAlias(String alias) {
    return $ContasTable(attachedDatabase, alias);
  }
}

class Conta extends DataClass implements Insertable<Conta> {
  final int id;
  final String remoteId;
  final String name;
  final String userId;
  final double saldoAtual;
  const Conta({
    required this.id,
    required this.remoteId,
    required this.name,
    required this.userId,
    required this.saldoAtual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    map['user_id'] = Variable<String>(userId);
    map['saldo_atual'] = Variable<double>(saldoAtual);
    return map;
  }

  ContasCompanion toCompanion(bool nullToAbsent) {
    return ContasCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      name: Value(name),
      userId: Value(userId),
      saldoAtual: Value(saldoAtual),
    );
  }

  factory Conta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conta(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String>(json['userId']),
      saldoAtual: serializer.fromJson<double>(json['saldoAtual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String>(userId),
      'saldoAtual': serializer.toJson<double>(saldoAtual),
    };
  }

  Conta copyWith({
    int? id,
    String? remoteId,
    String? name,
    String? userId,
    double? saldoAtual,
  }) => Conta(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    userId: userId ?? this.userId,
    saldoAtual: saldoAtual ?? this.saldoAtual,
  );
  Conta copyWithCompanion(ContasCompanion data) {
    return Conta(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      saldoAtual: data.saldoAtual.present
          ? data.saldoAtual.value
          : this.saldoAtual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conta(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('saldoAtual: $saldoAtual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remoteId, name, userId, saldoAtual);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conta &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.saldoAtual == this.saldoAtual);
}

class ContasCompanion extends UpdateCompanion<Conta> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<String> userId;
  final Value<double> saldoAtual;
  const ContasCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.saldoAtual = const Value.absent(),
  });
  ContasCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String name,
    required String userId,
    required double saldoAtual,
  }) : remoteId = Value(remoteId),
       name = Value(name),
       userId = Value(userId),
       saldoAtual = Value(saldoAtual);
  static Insertable<Conta> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<double>? saldoAtual,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (saldoAtual != null) 'saldo_atual': saldoAtual,
    });
  }

  ContasCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? name,
    Value<String>? userId,
    Value<double>? saldoAtual,
  }) {
    return ContasCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      saldoAtual: saldoAtual ?? this.saldoAtual,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (saldoAtual.present) {
      map['saldo_atual'] = Variable<double>(saldoAtual.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContasCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('saldoAtual: $saldoAtual')
          ..write(')'))
        .toString();
  }
}

class $ContatosTable extends Contatos with TableInfo<$ContatosTable, Contato> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContatosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _telefoneMeta = const VerificationMeta(
    'telefone',
  );
  @override
  late final GeneratedColumn<String> telefone = GeneratedColumn<String>(
    'telefone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    ownerId,
    nome,
    telefone,
    email,
    userId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contatos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Contato> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('telefone')) {
      context.handle(
        _telefoneMeta,
        telefone.isAcceptableOrUnknown(data['telefone']!, _telefoneMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Contato map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Contato(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      telefone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefone'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
    );
  }

  @override
  $ContatosTable createAlias(String alias) {
    return $ContatosTable(attachedDatabase, alias);
  }
}

class Contato extends DataClass implements Insertable<Contato> {
  final int id;
  final String remoteId;
  final String ownerId;
  final String nome;
  final String? telefone;
  final String? email;
  final String? userId;
  const Contato({
    required this.id,
    required this.remoteId,
    required this.ownerId,
    required this.nome,
    this.telefone,
    this.email,
    this.userId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['owner_id'] = Variable<String>(ownerId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || telefone != null) {
      map['telefone'] = Variable<String>(telefone);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    return map;
  }

  ContatosCompanion toCompanion(bool nullToAbsent) {
    return ContatosCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      ownerId: Value(ownerId),
      nome: Value(nome),
      telefone: telefone == null && nullToAbsent
          ? const Value.absent()
          : Value(telefone),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
    );
  }

  factory Contato.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Contato(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      nome: serializer.fromJson<String>(json['nome']),
      telefone: serializer.fromJson<String?>(json['telefone']),
      email: serializer.fromJson<String?>(json['email']),
      userId: serializer.fromJson<String?>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'ownerId': serializer.toJson<String>(ownerId),
      'nome': serializer.toJson<String>(nome),
      'telefone': serializer.toJson<String?>(telefone),
      'email': serializer.toJson<String?>(email),
      'userId': serializer.toJson<String?>(userId),
    };
  }

  Contato copyWith({
    int? id,
    String? remoteId,
    String? ownerId,
    String? nome,
    Value<String?> telefone = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> userId = const Value.absent(),
  }) => Contato(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    ownerId: ownerId ?? this.ownerId,
    nome: nome ?? this.nome,
    telefone: telefone.present ? telefone.value : this.telefone,
    email: email.present ? email.value : this.email,
    userId: userId.present ? userId.value : this.userId,
  );
  Contato copyWithCompanion(ContatosCompanion data) {
    return Contato(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      nome: data.nome.present ? data.nome.value : this.nome,
      telefone: data.telefone.present ? data.telefone.value : this.telefone,
      email: data.email.present ? data.email.value : this.email,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Contato(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerId: $ownerId, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, remoteId, ownerId, nome, telefone, email, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Contato &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.ownerId == this.ownerId &&
          other.nome == this.nome &&
          other.telefone == this.telefone &&
          other.email == this.email &&
          other.userId == this.userId);
}

class ContatosCompanion extends UpdateCompanion<Contato> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> ownerId;
  final Value<String> nome;
  final Value<String?> telefone;
  final Value<String?> email;
  final Value<String?> userId;
  const ContatosCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.nome = const Value.absent(),
    this.telefone = const Value.absent(),
    this.email = const Value.absent(),
    this.userId = const Value.absent(),
  });
  ContatosCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String ownerId,
    required String nome,
    this.telefone = const Value.absent(),
    this.email = const Value.absent(),
    this.userId = const Value.absent(),
  }) : remoteId = Value(remoteId),
       ownerId = Value(ownerId),
       nome = Value(nome);
  static Insertable<Contato> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? ownerId,
    Expression<String>? nome,
    Expression<String>? telefone,
    Expression<String>? email,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (ownerId != null) 'owner_id': ownerId,
      if (nome != null) 'nome': nome,
      if (telefone != null) 'telefone': telefone,
      if (email != null) 'email': email,
      if (userId != null) 'user_id': userId,
    });
  }

  ContatosCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? ownerId,
    Value<String>? nome,
    Value<String?>? telefone,
    Value<String?>? email,
    Value<String?>? userId,
  }) {
    return ContatosCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      ownerId: ownerId ?? this.ownerId,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (telefone.present) {
      map['telefone'] = Variable<String>(telefone.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContatosCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('ownerId: $ownerId, ')
          ..write('nome: $nome, ')
          ..write('telefone: $telefone, ')
          ..write('email: $email, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class $CategoriaTransacoesTable extends CategoriaTransacoes
    with TableInfo<$CategoriaTransacoesTable, CategoriaTransacoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriaTransacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconeMeta = const VerificationMeta('icone');
  @override
  late final GeneratedColumn<String> icone = GeneratedColumn<String>(
    'icone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _corHexMeta = const VerificationMeta('corHex');
  @override
  late final GeneratedColumn<String> corHex = GeneratedColumn<String>(
    'cor_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    nome,
    icone,
    corHex,
    userId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categoria_transacoes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoriaTransacoe> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('icone')) {
      context.handle(
        _iconeMeta,
        icone.isAcceptableOrUnknown(data['icone']!, _iconeMeta),
      );
    }
    if (data.containsKey('cor_hex')) {
      context.handle(
        _corHexMeta,
        corHex.isAcceptableOrUnknown(data['cor_hex']!, _corHexMeta),
      );
    } else if (isInserting) {
      context.missing(_corHexMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriaTransacoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriaTransacoe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      icone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icone'],
      ),
      corHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cor_hex'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
    );
  }

  @override
  $CategoriaTransacoesTable createAlias(String alias) {
    return $CategoriaTransacoesTable(attachedDatabase, alias);
  }
}

class CategoriaTransacoe extends DataClass
    implements Insertable<CategoriaTransacoe> {
  final int id;
  final String remoteId;
  final String nome;
  final String? icone;
  final String corHex;
  final String userId;
  const CategoriaTransacoe({
    required this.id,
    required this.remoteId,
    required this.nome,
    this.icone,
    required this.corHex,
    required this.userId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || icone != null) {
      map['icone'] = Variable<String>(icone);
    }
    map['cor_hex'] = Variable<String>(corHex);
    map['user_id'] = Variable<String>(userId);
    return map;
  }

  CategoriaTransacoesCompanion toCompanion(bool nullToAbsent) {
    return CategoriaTransacoesCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      nome: Value(nome),
      icone: icone == null && nullToAbsent
          ? const Value.absent()
          : Value(icone),
      corHex: Value(corHex),
      userId: Value(userId),
    );
  }

  factory CategoriaTransacoe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriaTransacoe(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      nome: serializer.fromJson<String>(json['nome']),
      icone: serializer.fromJson<String?>(json['icone']),
      corHex: serializer.fromJson<String>(json['corHex']),
      userId: serializer.fromJson<String>(json['userId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'nome': serializer.toJson<String>(nome),
      'icone': serializer.toJson<String?>(icone),
      'corHex': serializer.toJson<String>(corHex),
      'userId': serializer.toJson<String>(userId),
    };
  }

  CategoriaTransacoe copyWith({
    int? id,
    String? remoteId,
    String? nome,
    Value<String?> icone = const Value.absent(),
    String? corHex,
    String? userId,
  }) => CategoriaTransacoe(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    nome: nome ?? this.nome,
    icone: icone.present ? icone.value : this.icone,
    corHex: corHex ?? this.corHex,
    userId: userId ?? this.userId,
  );
  CategoriaTransacoe copyWithCompanion(CategoriaTransacoesCompanion data) {
    return CategoriaTransacoe(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      nome: data.nome.present ? data.nome.value : this.nome,
      icone: data.icone.present ? data.icone.value : this.icone,
      corHex: data.corHex.present ? data.corHex.value : this.corHex,
      userId: data.userId.present ? data.userId.value : this.userId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriaTransacoe(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('nome: $nome, ')
          ..write('icone: $icone, ')
          ..write('corHex: $corHex, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, remoteId, nome, icone, corHex, userId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriaTransacoe &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.nome == this.nome &&
          other.icone == this.icone &&
          other.corHex == this.corHex &&
          other.userId == this.userId);
}

class CategoriaTransacoesCompanion extends UpdateCompanion<CategoriaTransacoe> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> nome;
  final Value<String?> icone;
  final Value<String> corHex;
  final Value<String> userId;
  const CategoriaTransacoesCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.nome = const Value.absent(),
    this.icone = const Value.absent(),
    this.corHex = const Value.absent(),
    this.userId = const Value.absent(),
  });
  CategoriaTransacoesCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String nome,
    this.icone = const Value.absent(),
    required String corHex,
    required String userId,
  }) : remoteId = Value(remoteId),
       nome = Value(nome),
       corHex = Value(corHex),
       userId = Value(userId);
  static Insertable<CategoriaTransacoe> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? nome,
    Expression<String>? icone,
    Expression<String>? corHex,
    Expression<String>? userId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (nome != null) 'nome': nome,
      if (icone != null) 'icone': icone,
      if (corHex != null) 'cor_hex': corHex,
      if (userId != null) 'user_id': userId,
    });
  }

  CategoriaTransacoesCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? nome,
    Value<String?>? icone,
    Value<String>? corHex,
    Value<String>? userId,
  }) {
    return CategoriaTransacoesCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      userId: userId ?? this.userId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (icone.present) {
      map['icone'] = Variable<String>(icone.value);
    }
    if (corHex.present) {
      map['cor_hex'] = Variable<String>(corHex.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriaTransacoesCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('nome: $nome, ')
          ..write('icone: $icone, ')
          ..write('corHex: $corHex, ')
          ..write('userId: $userId')
          ..write(')'))
        .toString();
  }
}

class $TransacaosTable extends Transacaos
    with TableInfo<$TransacaosTable, Transacao> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransacaosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _descricaoMeta = const VerificationMeta(
    'descricao',
  );
  @override
  late final GeneratedColumn<String> descricao = GeneratedColumn<String>(
    'descricao',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataCompetenciaMeta = const VerificationMeta(
    'dataCompetencia',
  );
  @override
  late final GeneratedColumn<DateTime> dataCompetencia =
      GeneratedColumn<DateTime>(
        'data_competencia',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _consolidadaMeta = const VerificationMeta(
    'consolidada',
  );
  @override
  late final GeneratedColumn<bool> consolidada = GeneratedColumn<bool>(
    'consolidada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("consolidada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contaIdMeta = const VerificationMeta(
    'contaId',
  );
  @override
  late final GeneratedColumn<String> contaId = GeneratedColumn<String>(
    'conta_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contaDestinoIdMeta = const VerificationMeta(
    'contaDestinoId',
  );
  @override
  late final GeneratedColumn<String> contaDestinoId = GeneratedColumn<String>(
    'conta_destino_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriaIdMeta = const VerificationMeta(
    'categoriaId',
  );
  @override
  late final GeneratedColumn<String> categoriaId = GeneratedColumn<String>(
    'categoria_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _devedorContatoIdMeta = const VerificationMeta(
    'devedorContatoId',
  );
  @override
  late final GeneratedColumn<String> devedorContatoId = GeneratedColumn<String>(
    'devedor_contato_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _credorContatoIdMeta = const VerificationMeta(
    'credorContatoId',
  );
  @override
  late final GeneratedColumn<String> credorContatoId = GeneratedColumn<String>(
    'credor_contato_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<
    List<DivisaoTransacaoModel>,
    String
  >
  divisoes =
      GeneratedColumn<String>(
        'divisoes',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<DivisaoTransacaoModel>>(
        $TransacaosTable.$converterdivisoes,
      );
  @override
  late final GeneratedColumnWithTypeConverter<
    TransacaoRecorrenciaModel?,
    String
  >
  recorrencia =
      GeneratedColumn<String>(
        'recorrencia',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<TransacaoRecorrenciaModel?>(
        $TransacaosTable.$converterrecorrencian,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    remoteId,
    descricao,
    valor,
    tipo,
    dataCompetencia,
    consolidada,
    contaId,
    contaDestinoId,
    categoriaId,
    devedorContatoId,
    credorContatoId,
    divisoes,
    recorrencia,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transacaos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transacao> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('descricao')) {
      context.handle(
        _descricaoMeta,
        descricao.isAcceptableOrUnknown(data['descricao']!, _descricaoMeta),
      );
    } else if (isInserting) {
      context.missing(_descricaoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('data_competencia')) {
      context.handle(
        _dataCompetenciaMeta,
        dataCompetencia.isAcceptableOrUnknown(
          data['data_competencia']!,
          _dataCompetenciaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dataCompetenciaMeta);
    }
    if (data.containsKey('consolidada')) {
      context.handle(
        _consolidadaMeta,
        consolidada.isAcceptableOrUnknown(
          data['consolidada']!,
          _consolidadaMeta,
        ),
      );
    }
    if (data.containsKey('conta_id')) {
      context.handle(
        _contaIdMeta,
        contaId.isAcceptableOrUnknown(data['conta_id']!, _contaIdMeta),
      );
    }
    if (data.containsKey('conta_destino_id')) {
      context.handle(
        _contaDestinoIdMeta,
        contaDestinoId.isAcceptableOrUnknown(
          data['conta_destino_id']!,
          _contaDestinoIdMeta,
        ),
      );
    }
    if (data.containsKey('categoria_id')) {
      context.handle(
        _categoriaIdMeta,
        categoriaId.isAcceptableOrUnknown(
          data['categoria_id']!,
          _categoriaIdMeta,
        ),
      );
    }
    if (data.containsKey('devedor_contato_id')) {
      context.handle(
        _devedorContatoIdMeta,
        devedorContatoId.isAcceptableOrUnknown(
          data['devedor_contato_id']!,
          _devedorContatoIdMeta,
        ),
      );
    }
    if (data.containsKey('credor_contato_id')) {
      context.handle(
        _credorContatoIdMeta,
        credorContatoId.isAcceptableOrUnknown(
          data['credor_contato_id']!,
          _credorContatoIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transacao map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transacao(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      descricao: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descricao'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      dataCompetencia: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}data_competencia'],
      )!,
      consolidada: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}consolidada'],
      )!,
      contaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conta_id'],
      ),
      contaDestinoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conta_destino_id'],
      ),
      categoriaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_id'],
      ),
      devedorContatoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devedor_contato_id'],
      ),
      credorContatoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credor_contato_id'],
      ),
      divisoes: $TransacaosTable.$converterdivisoes.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}divisoes'],
        )!,
      ),
      recorrencia: $TransacaosTable.$converterrecorrencian.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recorrencia'],
        ),
      ),
    );
  }

  @override
  $TransacaosTable createAlias(String alias) {
    return $TransacaosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<DivisaoTransacaoModel>, String> $converterdivisoes =
      const DivisaoConverter();
  static TypeConverter<TransacaoRecorrenciaModel, String>
  $converterrecorrencia = const RecorrenciaConverter();
  static TypeConverter<TransacaoRecorrenciaModel?, String?>
  $converterrecorrencian = NullAwareTypeConverter.wrap($converterrecorrencia);
}

class Transacao extends DataClass implements Insertable<Transacao> {
  final int id;
  final String remoteId;
  final String descricao;
  final double valor;
  final String tipo;
  final DateTime dataCompetencia;
  final bool consolidada;
  final String? contaId;
  final String? contaDestinoId;
  final String? categoriaId;
  final String? devedorContatoId;
  final String? credorContatoId;
  final List<DivisaoTransacaoModel> divisoes;
  final TransacaoRecorrenciaModel? recorrencia;
  const Transacao({
    required this.id,
    required this.remoteId,
    required this.descricao,
    required this.valor,
    required this.tipo,
    required this.dataCompetencia,
    required this.consolidada,
    this.contaId,
    this.contaDestinoId,
    this.categoriaId,
    this.devedorContatoId,
    this.credorContatoId,
    required this.divisoes,
    this.recorrencia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['remote_id'] = Variable<String>(remoteId);
    map['descricao'] = Variable<String>(descricao);
    map['valor'] = Variable<double>(valor);
    map['tipo'] = Variable<String>(tipo);
    map['data_competencia'] = Variable<DateTime>(dataCompetencia);
    map['consolidada'] = Variable<bool>(consolidada);
    if (!nullToAbsent || contaId != null) {
      map['conta_id'] = Variable<String>(contaId);
    }
    if (!nullToAbsent || contaDestinoId != null) {
      map['conta_destino_id'] = Variable<String>(contaDestinoId);
    }
    if (!nullToAbsent || categoriaId != null) {
      map['categoria_id'] = Variable<String>(categoriaId);
    }
    if (!nullToAbsent || devedorContatoId != null) {
      map['devedor_contato_id'] = Variable<String>(devedorContatoId);
    }
    if (!nullToAbsent || credorContatoId != null) {
      map['credor_contato_id'] = Variable<String>(credorContatoId);
    }
    {
      map['divisoes'] = Variable<String>(
        $TransacaosTable.$converterdivisoes.toSql(divisoes),
      );
    }
    if (!nullToAbsent || recorrencia != null) {
      map['recorrencia'] = Variable<String>(
        $TransacaosTable.$converterrecorrencian.toSql(recorrencia),
      );
    }
    return map;
  }

  TransacaosCompanion toCompanion(bool nullToAbsent) {
    return TransacaosCompanion(
      id: Value(id),
      remoteId: Value(remoteId),
      descricao: Value(descricao),
      valor: Value(valor),
      tipo: Value(tipo),
      dataCompetencia: Value(dataCompetencia),
      consolidada: Value(consolidada),
      contaId: contaId == null && nullToAbsent
          ? const Value.absent()
          : Value(contaId),
      contaDestinoId: contaDestinoId == null && nullToAbsent
          ? const Value.absent()
          : Value(contaDestinoId),
      categoriaId: categoriaId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaId),
      devedorContatoId: devedorContatoId == null && nullToAbsent
          ? const Value.absent()
          : Value(devedorContatoId),
      credorContatoId: credorContatoId == null && nullToAbsent
          ? const Value.absent()
          : Value(credorContatoId),
      divisoes: Value(divisoes),
      recorrencia: recorrencia == null && nullToAbsent
          ? const Value.absent()
          : Value(recorrencia),
    );
  }

  factory Transacao.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transacao(
      id: serializer.fromJson<int>(json['id']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      descricao: serializer.fromJson<String>(json['descricao']),
      valor: serializer.fromJson<double>(json['valor']),
      tipo: serializer.fromJson<String>(json['tipo']),
      dataCompetencia: serializer.fromJson<DateTime>(json['dataCompetencia']),
      consolidada: serializer.fromJson<bool>(json['consolidada']),
      contaId: serializer.fromJson<String?>(json['contaId']),
      contaDestinoId: serializer.fromJson<String?>(json['contaDestinoId']),
      categoriaId: serializer.fromJson<String?>(json['categoriaId']),
      devedorContatoId: serializer.fromJson<String?>(json['devedorContatoId']),
      credorContatoId: serializer.fromJson<String?>(json['credorContatoId']),
      divisoes: serializer.fromJson<List<DivisaoTransacaoModel>>(
        json['divisoes'],
      ),
      recorrencia: serializer.fromJson<TransacaoRecorrenciaModel?>(
        json['recorrencia'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'remoteId': serializer.toJson<String>(remoteId),
      'descricao': serializer.toJson<String>(descricao),
      'valor': serializer.toJson<double>(valor),
      'tipo': serializer.toJson<String>(tipo),
      'dataCompetencia': serializer.toJson<DateTime>(dataCompetencia),
      'consolidada': serializer.toJson<bool>(consolidada),
      'contaId': serializer.toJson<String?>(contaId),
      'contaDestinoId': serializer.toJson<String?>(contaDestinoId),
      'categoriaId': serializer.toJson<String?>(categoriaId),
      'devedorContatoId': serializer.toJson<String?>(devedorContatoId),
      'credorContatoId': serializer.toJson<String?>(credorContatoId),
      'divisoes': serializer.toJson<List<DivisaoTransacaoModel>>(divisoes),
      'recorrencia': serializer.toJson<TransacaoRecorrenciaModel?>(recorrencia),
    };
  }

  Transacao copyWith({
    int? id,
    String? remoteId,
    String? descricao,
    double? valor,
    String? tipo,
    DateTime? dataCompetencia,
    bool? consolidada,
    Value<String?> contaId = const Value.absent(),
    Value<String?> contaDestinoId = const Value.absent(),
    Value<String?> categoriaId = const Value.absent(),
    Value<String?> devedorContatoId = const Value.absent(),
    Value<String?> credorContatoId = const Value.absent(),
    List<DivisaoTransacaoModel>? divisoes,
    Value<TransacaoRecorrenciaModel?> recorrencia = const Value.absent(),
  }) => Transacao(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    descricao: descricao ?? this.descricao,
    valor: valor ?? this.valor,
    tipo: tipo ?? this.tipo,
    dataCompetencia: dataCompetencia ?? this.dataCompetencia,
    consolidada: consolidada ?? this.consolidada,
    contaId: contaId.present ? contaId.value : this.contaId,
    contaDestinoId: contaDestinoId.present
        ? contaDestinoId.value
        : this.contaDestinoId,
    categoriaId: categoriaId.present ? categoriaId.value : this.categoriaId,
    devedorContatoId: devedorContatoId.present
        ? devedorContatoId.value
        : this.devedorContatoId,
    credorContatoId: credorContatoId.present
        ? credorContatoId.value
        : this.credorContatoId,
    divisoes: divisoes ?? this.divisoes,
    recorrencia: recorrencia.present ? recorrencia.value : this.recorrencia,
  );
  Transacao copyWithCompanion(TransacaosCompanion data) {
    return Transacao(
      id: data.id.present ? data.id.value : this.id,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      descricao: data.descricao.present ? data.descricao.value : this.descricao,
      valor: data.valor.present ? data.valor.value : this.valor,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      dataCompetencia: data.dataCompetencia.present
          ? data.dataCompetencia.value
          : this.dataCompetencia,
      consolidada: data.consolidada.present
          ? data.consolidada.value
          : this.consolidada,
      contaId: data.contaId.present ? data.contaId.value : this.contaId,
      contaDestinoId: data.contaDestinoId.present
          ? data.contaDestinoId.value
          : this.contaDestinoId,
      categoriaId: data.categoriaId.present
          ? data.categoriaId.value
          : this.categoriaId,
      devedorContatoId: data.devedorContatoId.present
          ? data.devedorContatoId.value
          : this.devedorContatoId,
      credorContatoId: data.credorContatoId.present
          ? data.credorContatoId.value
          : this.credorContatoId,
      divisoes: data.divisoes.present ? data.divisoes.value : this.divisoes,
      recorrencia: data.recorrencia.present
          ? data.recorrencia.value
          : this.recorrencia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transacao(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo, ')
          ..write('dataCompetencia: $dataCompetencia, ')
          ..write('consolidada: $consolidada, ')
          ..write('contaId: $contaId, ')
          ..write('contaDestinoId: $contaDestinoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('devedorContatoId: $devedorContatoId, ')
          ..write('credorContatoId: $credorContatoId, ')
          ..write('divisoes: $divisoes, ')
          ..write('recorrencia: $recorrencia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    remoteId,
    descricao,
    valor,
    tipo,
    dataCompetencia,
    consolidada,
    contaId,
    contaDestinoId,
    categoriaId,
    devedorContatoId,
    credorContatoId,
    divisoes,
    recorrencia,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transacao &&
          other.id == this.id &&
          other.remoteId == this.remoteId &&
          other.descricao == this.descricao &&
          other.valor == this.valor &&
          other.tipo == this.tipo &&
          other.dataCompetencia == this.dataCompetencia &&
          other.consolidada == this.consolidada &&
          other.contaId == this.contaId &&
          other.contaDestinoId == this.contaDestinoId &&
          other.categoriaId == this.categoriaId &&
          other.devedorContatoId == this.devedorContatoId &&
          other.credorContatoId == this.credorContatoId &&
          other.divisoes == this.divisoes &&
          other.recorrencia == this.recorrencia);
}

class TransacaosCompanion extends UpdateCompanion<Transacao> {
  final Value<int> id;
  final Value<String> remoteId;
  final Value<String> descricao;
  final Value<double> valor;
  final Value<String> tipo;
  final Value<DateTime> dataCompetencia;
  final Value<bool> consolidada;
  final Value<String?> contaId;
  final Value<String?> contaDestinoId;
  final Value<String?> categoriaId;
  final Value<String?> devedorContatoId;
  final Value<String?> credorContatoId;
  final Value<List<DivisaoTransacaoModel>> divisoes;
  final Value<TransacaoRecorrenciaModel?> recorrencia;
  const TransacaosCompanion({
    this.id = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.descricao = const Value.absent(),
    this.valor = const Value.absent(),
    this.tipo = const Value.absent(),
    this.dataCompetencia = const Value.absent(),
    this.consolidada = const Value.absent(),
    this.contaId = const Value.absent(),
    this.contaDestinoId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.devedorContatoId = const Value.absent(),
    this.credorContatoId = const Value.absent(),
    this.divisoes = const Value.absent(),
    this.recorrencia = const Value.absent(),
  });
  TransacaosCompanion.insert({
    this.id = const Value.absent(),
    required String remoteId,
    required String descricao,
    required double valor,
    required String tipo,
    required DateTime dataCompetencia,
    this.consolidada = const Value.absent(),
    this.contaId = const Value.absent(),
    this.contaDestinoId = const Value.absent(),
    this.categoriaId = const Value.absent(),
    this.devedorContatoId = const Value.absent(),
    this.credorContatoId = const Value.absent(),
    required List<DivisaoTransacaoModel> divisoes,
    this.recorrencia = const Value.absent(),
  }) : remoteId = Value(remoteId),
       descricao = Value(descricao),
       valor = Value(valor),
       tipo = Value(tipo),
       dataCompetencia = Value(dataCompetencia),
       divisoes = Value(divisoes);
  static Insertable<Transacao> custom({
    Expression<int>? id,
    Expression<String>? remoteId,
    Expression<String>? descricao,
    Expression<double>? valor,
    Expression<String>? tipo,
    Expression<DateTime>? dataCompetencia,
    Expression<bool>? consolidada,
    Expression<String>? contaId,
    Expression<String>? contaDestinoId,
    Expression<String>? categoriaId,
    Expression<String>? devedorContatoId,
    Expression<String>? credorContatoId,
    Expression<String>? divisoes,
    Expression<String>? recorrencia,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (remoteId != null) 'remote_id': remoteId,
      if (descricao != null) 'descricao': descricao,
      if (valor != null) 'valor': valor,
      if (tipo != null) 'tipo': tipo,
      if (dataCompetencia != null) 'data_competencia': dataCompetencia,
      if (consolidada != null) 'consolidada': consolidada,
      if (contaId != null) 'conta_id': contaId,
      if (contaDestinoId != null) 'conta_destino_id': contaDestinoId,
      if (categoriaId != null) 'categoria_id': categoriaId,
      if (devedorContatoId != null) 'devedor_contato_id': devedorContatoId,
      if (credorContatoId != null) 'credor_contato_id': credorContatoId,
      if (divisoes != null) 'divisoes': divisoes,
      if (recorrencia != null) 'recorrencia': recorrencia,
    });
  }

  TransacaosCompanion copyWith({
    Value<int>? id,
    Value<String>? remoteId,
    Value<String>? descricao,
    Value<double>? valor,
    Value<String>? tipo,
    Value<DateTime>? dataCompetencia,
    Value<bool>? consolidada,
    Value<String?>? contaId,
    Value<String?>? contaDestinoId,
    Value<String?>? categoriaId,
    Value<String?>? devedorContatoId,
    Value<String?>? credorContatoId,
    Value<List<DivisaoTransacaoModel>>? divisoes,
    Value<TransacaoRecorrenciaModel?>? recorrencia,
  }) {
    return TransacaosCompanion(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      dataCompetencia: dataCompetencia ?? this.dataCompetencia,
      consolidada: consolidada ?? this.consolidada,
      contaId: contaId ?? this.contaId,
      contaDestinoId: contaDestinoId ?? this.contaDestinoId,
      categoriaId: categoriaId ?? this.categoriaId,
      devedorContatoId: devedorContatoId ?? this.devedorContatoId,
      credorContatoId: credorContatoId ?? this.credorContatoId,
      divisoes: divisoes ?? this.divisoes,
      recorrencia: recorrencia ?? this.recorrencia,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (descricao.present) {
      map['descricao'] = Variable<String>(descricao.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (dataCompetencia.present) {
      map['data_competencia'] = Variable<DateTime>(dataCompetencia.value);
    }
    if (consolidada.present) {
      map['consolidada'] = Variable<bool>(consolidada.value);
    }
    if (contaId.present) {
      map['conta_id'] = Variable<String>(contaId.value);
    }
    if (contaDestinoId.present) {
      map['conta_destino_id'] = Variable<String>(contaDestinoId.value);
    }
    if (categoriaId.present) {
      map['categoria_id'] = Variable<String>(categoriaId.value);
    }
    if (devedorContatoId.present) {
      map['devedor_contato_id'] = Variable<String>(devedorContatoId.value);
    }
    if (credorContatoId.present) {
      map['credor_contato_id'] = Variable<String>(credorContatoId.value);
    }
    if (divisoes.present) {
      map['divisoes'] = Variable<String>(
        $TransacaosTable.$converterdivisoes.toSql(divisoes.value),
      );
    }
    if (recorrencia.present) {
      map['recorrencia'] = Variable<String>(
        $TransacaosTable.$converterrecorrencian.toSql(recorrencia.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransacaosCompanion(')
          ..write('id: $id, ')
          ..write('remoteId: $remoteId, ')
          ..write('descricao: $descricao, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo, ')
          ..write('dataCompetencia: $dataCompetencia, ')
          ..write('consolidada: $consolidada, ')
          ..write('contaId: $contaId, ')
          ..write('contaDestinoId: $contaDestinoId, ')
          ..write('categoriaId: $categoriaId, ')
          ..write('devedorContatoId: $devedorContatoId, ')
          ..write('credorContatoId: $credorContatoId, ')
          ..write('divisoes: $divisoes, ')
          ..write('recorrencia: $recorrencia')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $TarefaHabitosTable tarefaHabitos = $TarefaHabitosTable(this);
  late final $HistoricoTarefasHabitosTable historicoTarefasHabitos =
      $HistoricoTarefasHabitosTable(this);
  late final $ContasTable contas = $ContasTable(this);
  late final $ContatosTable contatos = $ContatosTable(this);
  late final $CategoriaTransacoesTable categoriaTransacoes =
      $CategoriaTransacoesTable(this);
  late final $TransacaosTable transacaos = $TransacaosTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    tarefaHabitos,
    historicoTarefasHabitos,
    contas,
    contatos,
    categoriaTransacoes,
    transacaos,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      required String key,
      required String value,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String> value,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
              }) => AppSettingsCompanion(id: id, key: key, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                required String value,
              }) => AppSettingsCompanion.insert(id: id, key: key, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$TarefaHabitosTableCreateCompanionBuilder =
    TarefaHabitosCompanion Function({
      Value<int> id,
      required String remoteId,
      required String nome,
      required String tipo,
      required String usuario,
      required bool concluida,
      Value<DateTime?> agendamento,
      Value<int?> duration,
      required List<TarefaHabitoQtdModel> metas,
    });
typedef $$TarefaHabitosTableUpdateCompanionBuilder =
    TarefaHabitosCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> nome,
      Value<String> tipo,
      Value<String> usuario,
      Value<bool> concluida,
      Value<DateTime?> agendamento,
      Value<int?> duration,
      Value<List<TarefaHabitoQtdModel>> metas,
    });

class $$TarefaHabitosTableFilterComposer
    extends Composer<_$AppDatabase, $TarefaHabitosTable> {
  $$TarefaHabitosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get concluida => $composableBuilder(
    column: $table.concluida,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get agendamento => $composableBuilder(
    column: $table.agendamento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<TarefaHabitoQtdModel>,
    List<TarefaHabitoQtdModel>,
    String
  >
  get metas => $composableBuilder(
    column: $table.metas,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$TarefaHabitosTableOrderingComposer
    extends Composer<_$AppDatabase, $TarefaHabitosTable> {
  $$TarefaHabitosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get concluida => $composableBuilder(
    column: $table.concluida,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get agendamento => $composableBuilder(
    column: $table.agendamento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metas => $composableBuilder(
    column: $table.metas,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TarefaHabitosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TarefaHabitosTable> {
  $$TarefaHabitosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get usuario =>
      $composableBuilder(column: $table.usuario, builder: (column) => column);

  GeneratedColumn<bool> get concluida =>
      $composableBuilder(column: $table.concluida, builder: (column) => column);

  GeneratedColumn<DateTime> get agendamento => $composableBuilder(
    column: $table.agendamento,
    builder: (column) => column,
  );

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TarefaHabitoQtdModel>, String>
  get metas =>
      $composableBuilder(column: $table.metas, builder: (column) => column);
}

class $$TarefaHabitosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TarefaHabitosTable,
          TarefaHabito,
          $$TarefaHabitosTableFilterComposer,
          $$TarefaHabitosTableOrderingComposer,
          $$TarefaHabitosTableAnnotationComposer,
          $$TarefaHabitosTableCreateCompanionBuilder,
          $$TarefaHabitosTableUpdateCompanionBuilder,
          (
            TarefaHabito,
            BaseReferences<_$AppDatabase, $TarefaHabitosTable, TarefaHabito>,
          ),
          TarefaHabito,
          PrefetchHooks Function()
        > {
  $$TarefaHabitosTableTableManager(_$AppDatabase db, $TarefaHabitosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TarefaHabitosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TarefaHabitosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TarefaHabitosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> usuario = const Value.absent(),
                Value<bool> concluida = const Value.absent(),
                Value<DateTime?> agendamento = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<List<TarefaHabitoQtdModel>> metas = const Value.absent(),
              }) => TarefaHabitosCompanion(
                id: id,
                remoteId: remoteId,
                nome: nome,
                tipo: tipo,
                usuario: usuario,
                concluida: concluida,
                agendamento: agendamento,
                duration: duration,
                metas: metas,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String nome,
                required String tipo,
                required String usuario,
                required bool concluida,
                Value<DateTime?> agendamento = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                required List<TarefaHabitoQtdModel> metas,
              }) => TarefaHabitosCompanion.insert(
                id: id,
                remoteId: remoteId,
                nome: nome,
                tipo: tipo,
                usuario: usuario,
                concluida: concluida,
                agendamento: agendamento,
                duration: duration,
                metas: metas,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TarefaHabitosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TarefaHabitosTable,
      TarefaHabito,
      $$TarefaHabitosTableFilterComposer,
      $$TarefaHabitosTableOrderingComposer,
      $$TarefaHabitosTableAnnotationComposer,
      $$TarefaHabitosTableCreateCompanionBuilder,
      $$TarefaHabitosTableUpdateCompanionBuilder,
      (
        TarefaHabito,
        BaseReferences<_$AppDatabase, $TarefaHabitosTable, TarefaHabito>,
      ),
      TarefaHabito,
      PrefetchHooks Function()
    >;
typedef $$HistoricoTarefasHabitosTableCreateCompanionBuilder =
    HistoricoTarefasHabitosCompanion Function({
      Value<int> id,
      required String remoteId,
      required String usuario,
      required String tarefaHabitoId,
      required DateTime createdAt,
    });
typedef $$HistoricoTarefasHabitosTableUpdateCompanionBuilder =
    HistoricoTarefasHabitosCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> usuario,
      Value<String> tarefaHabitoId,
      Value<DateTime> createdAt,
    });

class $$HistoricoTarefasHabitosTableFilterComposer
    extends Composer<_$AppDatabase, $HistoricoTarefasHabitosTable> {
  $$HistoricoTarefasHabitosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tarefaHabitoId => $composableBuilder(
    column: $table.tarefaHabitoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoricoTarefasHabitosTableOrderingComposer
    extends Composer<_$AppDatabase, $HistoricoTarefasHabitosTable> {
  $$HistoricoTarefasHabitosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuario => $composableBuilder(
    column: $table.usuario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tarefaHabitoId => $composableBuilder(
    column: $table.tarefaHabitoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoricoTarefasHabitosTableAnnotationComposer
    extends Composer<_$AppDatabase, $HistoricoTarefasHabitosTable> {
  $$HistoricoTarefasHabitosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get usuario =>
      $composableBuilder(column: $table.usuario, builder: (column) => column);

  GeneratedColumn<String> get tarefaHabitoId => $composableBuilder(
    column: $table.tarefaHabitoId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HistoricoTarefasHabitosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HistoricoTarefasHabitosTable,
          HistoricoTarefasHabito,
          $$HistoricoTarefasHabitosTableFilterComposer,
          $$HistoricoTarefasHabitosTableOrderingComposer,
          $$HistoricoTarefasHabitosTableAnnotationComposer,
          $$HistoricoTarefasHabitosTableCreateCompanionBuilder,
          $$HistoricoTarefasHabitosTableUpdateCompanionBuilder,
          (
            HistoricoTarefasHabito,
            BaseReferences<
              _$AppDatabase,
              $HistoricoTarefasHabitosTable,
              HistoricoTarefasHabito
            >,
          ),
          HistoricoTarefasHabito,
          PrefetchHooks Function()
        > {
  $$HistoricoTarefasHabitosTableTableManager(
    _$AppDatabase db,
    $HistoricoTarefasHabitosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoricoTarefasHabitosTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$HistoricoTarefasHabitosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$HistoricoTarefasHabitosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> usuario = const Value.absent(),
                Value<String> tarefaHabitoId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HistoricoTarefasHabitosCompanion(
                id: id,
                remoteId: remoteId,
                usuario: usuario,
                tarefaHabitoId: tarefaHabitoId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String usuario,
                required String tarefaHabitoId,
                required DateTime createdAt,
              }) => HistoricoTarefasHabitosCompanion.insert(
                id: id,
                remoteId: remoteId,
                usuario: usuario,
                tarefaHabitoId: tarefaHabitoId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoricoTarefasHabitosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HistoricoTarefasHabitosTable,
      HistoricoTarefasHabito,
      $$HistoricoTarefasHabitosTableFilterComposer,
      $$HistoricoTarefasHabitosTableOrderingComposer,
      $$HistoricoTarefasHabitosTableAnnotationComposer,
      $$HistoricoTarefasHabitosTableCreateCompanionBuilder,
      $$HistoricoTarefasHabitosTableUpdateCompanionBuilder,
      (
        HistoricoTarefasHabito,
        BaseReferences<
          _$AppDatabase,
          $HistoricoTarefasHabitosTable,
          HistoricoTarefasHabito
        >,
      ),
      HistoricoTarefasHabito,
      PrefetchHooks Function()
    >;
typedef $$ContasTableCreateCompanionBuilder =
    ContasCompanion Function({
      Value<int> id,
      required String remoteId,
      required String name,
      required String userId,
      required double saldoAtual,
    });
typedef $$ContasTableUpdateCompanionBuilder =
    ContasCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> name,
      Value<String> userId,
      Value<double> saldoAtual,
    });

class $$ContasTableFilterComposer
    extends Composer<_$AppDatabase, $ContasTable> {
  $$ContasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get saldoAtual => $composableBuilder(
    column: $table.saldoAtual,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContasTableOrderingComposer
    extends Composer<_$AppDatabase, $ContasTable> {
  $$ContasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get saldoAtual => $composableBuilder(
    column: $table.saldoAtual,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContasTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContasTable> {
  $$ContasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get saldoAtual => $composableBuilder(
    column: $table.saldoAtual,
    builder: (column) => column,
  );
}

class $$ContasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContasTable,
          Conta,
          $$ContasTableFilterComposer,
          $$ContasTableOrderingComposer,
          $$ContasTableAnnotationComposer,
          $$ContasTableCreateCompanionBuilder,
          $$ContasTableUpdateCompanionBuilder,
          (Conta, BaseReferences<_$AppDatabase, $ContasTable, Conta>),
          Conta,
          PrefetchHooks Function()
        > {
  $$ContasTableTableManager(_$AppDatabase db, $ContasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<double> saldoAtual = const Value.absent(),
              }) => ContasCompanion(
                id: id,
                remoteId: remoteId,
                name: name,
                userId: userId,
                saldoAtual: saldoAtual,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String name,
                required String userId,
                required double saldoAtual,
              }) => ContasCompanion.insert(
                id: id,
                remoteId: remoteId,
                name: name,
                userId: userId,
                saldoAtual: saldoAtual,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContasTable,
      Conta,
      $$ContasTableFilterComposer,
      $$ContasTableOrderingComposer,
      $$ContasTableAnnotationComposer,
      $$ContasTableCreateCompanionBuilder,
      $$ContasTableUpdateCompanionBuilder,
      (Conta, BaseReferences<_$AppDatabase, $ContasTable, Conta>),
      Conta,
      PrefetchHooks Function()
    >;
typedef $$ContatosTableCreateCompanionBuilder =
    ContatosCompanion Function({
      Value<int> id,
      required String remoteId,
      required String ownerId,
      required String nome,
      Value<String?> telefone,
      Value<String?> email,
      Value<String?> userId,
    });
typedef $$ContatosTableUpdateCompanionBuilder =
    ContatosCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> ownerId,
      Value<String> nome,
      Value<String?> telefone,
      Value<String?> email,
      Value<String?> userId,
    });

class $$ContatosTableFilterComposer
    extends Composer<_$AppDatabase, $ContatosTable> {
  $$ContatosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContatosTableOrderingComposer
    extends Composer<_$AppDatabase, $ContatosTable> {
  $$ContatosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefone => $composableBuilder(
    column: $table.telefone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContatosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContatosTable> {
  $$ContatosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get telefone =>
      $composableBuilder(column: $table.telefone, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$ContatosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContatosTable,
          Contato,
          $$ContatosTableFilterComposer,
          $$ContatosTableOrderingComposer,
          $$ContatosTableAnnotationComposer,
          $$ContatosTableCreateCompanionBuilder,
          $$ContatosTableUpdateCompanionBuilder,
          (Contato, BaseReferences<_$AppDatabase, $ContatosTable, Contato>),
          Contato,
          PrefetchHooks Function()
        > {
  $$ContatosTableTableManager(_$AppDatabase db, $ContatosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContatosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContatosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContatosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> telefone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> userId = const Value.absent(),
              }) => ContatosCompanion(
                id: id,
                remoteId: remoteId,
                ownerId: ownerId,
                nome: nome,
                telefone: telefone,
                email: email,
                userId: userId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String ownerId,
                required String nome,
                Value<String?> telefone = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> userId = const Value.absent(),
              }) => ContatosCompanion.insert(
                id: id,
                remoteId: remoteId,
                ownerId: ownerId,
                nome: nome,
                telefone: telefone,
                email: email,
                userId: userId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContatosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContatosTable,
      Contato,
      $$ContatosTableFilterComposer,
      $$ContatosTableOrderingComposer,
      $$ContatosTableAnnotationComposer,
      $$ContatosTableCreateCompanionBuilder,
      $$ContatosTableUpdateCompanionBuilder,
      (Contato, BaseReferences<_$AppDatabase, $ContatosTable, Contato>),
      Contato,
      PrefetchHooks Function()
    >;
typedef $$CategoriaTransacoesTableCreateCompanionBuilder =
    CategoriaTransacoesCompanion Function({
      Value<int> id,
      required String remoteId,
      required String nome,
      Value<String?> icone,
      required String corHex,
      required String userId,
    });
typedef $$CategoriaTransacoesTableUpdateCompanionBuilder =
    CategoriaTransacoesCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> nome,
      Value<String?> icone,
      Value<String> corHex,
      Value<String> userId,
    });

class $$CategoriaTransacoesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriaTransacoesTable> {
  $$CategoriaTransacoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icone => $composableBuilder(
    column: $table.icone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get corHex => $composableBuilder(
    column: $table.corHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriaTransacoesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriaTransacoesTable> {
  $$CategoriaTransacoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icone => $composableBuilder(
    column: $table.icone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get corHex => $composableBuilder(
    column: $table.corHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriaTransacoesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriaTransacoesTable> {
  $$CategoriaTransacoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<String> get icone =>
      $composableBuilder(column: $table.icone, builder: (column) => column);

  GeneratedColumn<String> get corHex =>
      $composableBuilder(column: $table.corHex, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);
}

class $$CategoriaTransacoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriaTransacoesTable,
          CategoriaTransacoe,
          $$CategoriaTransacoesTableFilterComposer,
          $$CategoriaTransacoesTableOrderingComposer,
          $$CategoriaTransacoesTableAnnotationComposer,
          $$CategoriaTransacoesTableCreateCompanionBuilder,
          $$CategoriaTransacoesTableUpdateCompanionBuilder,
          (
            CategoriaTransacoe,
            BaseReferences<
              _$AppDatabase,
              $CategoriaTransacoesTable,
              CategoriaTransacoe
            >,
          ),
          CategoriaTransacoe,
          PrefetchHooks Function()
        > {
  $$CategoriaTransacoesTableTableManager(
    _$AppDatabase db,
    $CategoriaTransacoesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriaTransacoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriaTransacoesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CategoriaTransacoesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<String?> icone = const Value.absent(),
                Value<String> corHex = const Value.absent(),
                Value<String> userId = const Value.absent(),
              }) => CategoriaTransacoesCompanion(
                id: id,
                remoteId: remoteId,
                nome: nome,
                icone: icone,
                corHex: corHex,
                userId: userId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String nome,
                Value<String?> icone = const Value.absent(),
                required String corHex,
                required String userId,
              }) => CategoriaTransacoesCompanion.insert(
                id: id,
                remoteId: remoteId,
                nome: nome,
                icone: icone,
                corHex: corHex,
                userId: userId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriaTransacoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriaTransacoesTable,
      CategoriaTransacoe,
      $$CategoriaTransacoesTableFilterComposer,
      $$CategoriaTransacoesTableOrderingComposer,
      $$CategoriaTransacoesTableAnnotationComposer,
      $$CategoriaTransacoesTableCreateCompanionBuilder,
      $$CategoriaTransacoesTableUpdateCompanionBuilder,
      (
        CategoriaTransacoe,
        BaseReferences<
          _$AppDatabase,
          $CategoriaTransacoesTable,
          CategoriaTransacoe
        >,
      ),
      CategoriaTransacoe,
      PrefetchHooks Function()
    >;
typedef $$TransacaosTableCreateCompanionBuilder =
    TransacaosCompanion Function({
      Value<int> id,
      required String remoteId,
      required String descricao,
      required double valor,
      required String tipo,
      required DateTime dataCompetencia,
      Value<bool> consolidada,
      Value<String?> contaId,
      Value<String?> contaDestinoId,
      Value<String?> categoriaId,
      Value<String?> devedorContatoId,
      Value<String?> credorContatoId,
      required List<DivisaoTransacaoModel> divisoes,
      Value<TransacaoRecorrenciaModel?> recorrencia,
    });
typedef $$TransacaosTableUpdateCompanionBuilder =
    TransacaosCompanion Function({
      Value<int> id,
      Value<String> remoteId,
      Value<String> descricao,
      Value<double> valor,
      Value<String> tipo,
      Value<DateTime> dataCompetencia,
      Value<bool> consolidada,
      Value<String?> contaId,
      Value<String?> contaDestinoId,
      Value<String?> categoriaId,
      Value<String?> devedorContatoId,
      Value<String?> credorContatoId,
      Value<List<DivisaoTransacaoModel>> divisoes,
      Value<TransacaoRecorrenciaModel?> recorrencia,
    });

class $$TransacaosTableFilterComposer
    extends Composer<_$AppDatabase, $TransacaosTable> {
  $$TransacaosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dataCompetencia => $composableBuilder(
    column: $table.dataCompetencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get consolidada => $composableBuilder(
    column: $table.consolidada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contaId => $composableBuilder(
    column: $table.contaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contaDestinoId => $composableBuilder(
    column: $table.contaDestinoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devedorContatoId => $composableBuilder(
    column: $table.devedorContatoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credorContatoId => $composableBuilder(
    column: $table.credorContatoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<DivisaoTransacaoModel>,
    List<DivisaoTransacaoModel>,
    String
  >
  get divisoes => $composableBuilder(
    column: $table.divisoes,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    TransacaoRecorrenciaModel?,
    TransacaoRecorrenciaModel,
    String
  >
  get recorrencia => $composableBuilder(
    column: $table.recorrencia,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$TransacaosTableOrderingComposer
    extends Composer<_$AppDatabase, $TransacaosTable> {
  $$TransacaosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descricao => $composableBuilder(
    column: $table.descricao,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dataCompetencia => $composableBuilder(
    column: $table.dataCompetencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get consolidada => $composableBuilder(
    column: $table.consolidada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contaId => $composableBuilder(
    column: $table.contaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contaDestinoId => $composableBuilder(
    column: $table.contaDestinoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devedorContatoId => $composableBuilder(
    column: $table.devedorContatoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credorContatoId => $composableBuilder(
    column: $table.credorContatoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get divisoes => $composableBuilder(
    column: $table.divisoes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recorrencia => $composableBuilder(
    column: $table.recorrencia,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransacaosTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransacaosTable> {
  $$TransacaosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get descricao =>
      $composableBuilder(column: $table.descricao, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get dataCompetencia => $composableBuilder(
    column: $table.dataCompetencia,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get consolidada => $composableBuilder(
    column: $table.consolidada,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contaId =>
      $composableBuilder(column: $table.contaId, builder: (column) => column);

  GeneratedColumn<String> get contaDestinoId => $composableBuilder(
    column: $table.contaDestinoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoriaId => $composableBuilder(
    column: $table.categoriaId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devedorContatoId => $composableBuilder(
    column: $table.devedorContatoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get credorContatoId => $composableBuilder(
    column: $table.credorContatoId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<DivisaoTransacaoModel>, String>
  get divisoes =>
      $composableBuilder(column: $table.divisoes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransacaoRecorrenciaModel?, String>
  get recorrencia => $composableBuilder(
    column: $table.recorrencia,
    builder: (column) => column,
  );
}

class $$TransacaosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransacaosTable,
          Transacao,
          $$TransacaosTableFilterComposer,
          $$TransacaosTableOrderingComposer,
          $$TransacaosTableAnnotationComposer,
          $$TransacaosTableCreateCompanionBuilder,
          $$TransacaosTableUpdateCompanionBuilder,
          (
            Transacao,
            BaseReferences<_$AppDatabase, $TransacaosTable, Transacao>,
          ),
          Transacao,
          PrefetchHooks Function()
        > {
  $$TransacaosTableTableManager(_$AppDatabase db, $TransacaosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransacaosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransacaosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransacaosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> descricao = const Value.absent(),
                Value<double> valor = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> dataCompetencia = const Value.absent(),
                Value<bool> consolidada = const Value.absent(),
                Value<String?> contaId = const Value.absent(),
                Value<String?> contaDestinoId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String?> devedorContatoId = const Value.absent(),
                Value<String?> credorContatoId = const Value.absent(),
                Value<List<DivisaoTransacaoModel>> divisoes =
                    const Value.absent(),
                Value<TransacaoRecorrenciaModel?> recorrencia =
                    const Value.absent(),
              }) => TransacaosCompanion(
                id: id,
                remoteId: remoteId,
                descricao: descricao,
                valor: valor,
                tipo: tipo,
                dataCompetencia: dataCompetencia,
                consolidada: consolidada,
                contaId: contaId,
                contaDestinoId: contaDestinoId,
                categoriaId: categoriaId,
                devedorContatoId: devedorContatoId,
                credorContatoId: credorContatoId,
                divisoes: divisoes,
                recorrencia: recorrencia,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String remoteId,
                required String descricao,
                required double valor,
                required String tipo,
                required DateTime dataCompetencia,
                Value<bool> consolidada = const Value.absent(),
                Value<String?> contaId = const Value.absent(),
                Value<String?> contaDestinoId = const Value.absent(),
                Value<String?> categoriaId = const Value.absent(),
                Value<String?> devedorContatoId = const Value.absent(),
                Value<String?> credorContatoId = const Value.absent(),
                required List<DivisaoTransacaoModel> divisoes,
                Value<TransacaoRecorrenciaModel?> recorrencia =
                    const Value.absent(),
              }) => TransacaosCompanion.insert(
                id: id,
                remoteId: remoteId,
                descricao: descricao,
                valor: valor,
                tipo: tipo,
                dataCompetencia: dataCompetencia,
                consolidada: consolidada,
                contaId: contaId,
                contaDestinoId: contaDestinoId,
                categoriaId: categoriaId,
                devedorContatoId: devedorContatoId,
                credorContatoId: credorContatoId,
                divisoes: divisoes,
                recorrencia: recorrencia,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransacaosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransacaosTable,
      Transacao,
      $$TransacaosTableFilterComposer,
      $$TransacaosTableOrderingComposer,
      $$TransacaosTableAnnotationComposer,
      $$TransacaosTableCreateCompanionBuilder,
      $$TransacaosTableUpdateCompanionBuilder,
      (Transacao, BaseReferences<_$AppDatabase, $TransacaosTable, Transacao>),
      Transacao,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$TarefaHabitosTableTableManager get tarefaHabitos =>
      $$TarefaHabitosTableTableManager(_db, _db.tarefaHabitos);
  $$HistoricoTarefasHabitosTableTableManager get historicoTarefasHabitos =>
      $$HistoricoTarefasHabitosTableTableManager(
        _db,
        _db.historicoTarefasHabitos,
      );
  $$ContasTableTableManager get contas =>
      $$ContasTableTableManager(_db, _db.contas);
  $$ContatosTableTableManager get contatos =>
      $$ContatosTableTableManager(_db, _db.contatos);
  $$CategoriaTransacoesTableTableManager get categoriaTransacoes =>
      $$CategoriaTransacoesTableTableManager(_db, _db.categoriaTransacoes);
  $$TransacaosTableTableManager get transacaos =>
      $$TransacaosTableTableManager(_db, _db.transacaos);
}
