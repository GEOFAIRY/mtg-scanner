// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CollectionTable extends Collection
    with TableInfo<$CollectionTable, CollectionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _scryfallIdMeta = const VerificationMeta(
    'scryfallId',
  );
  @override
  late final GeneratedColumn<String> scryfallId = GeneratedColumn<String>(
    'scryfall_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _setCodeMeta = const VerificationMeta(
    'setCode',
  );
  @override
  late final GeneratedColumn<String> setCode = GeneratedColumn<String>(
    'set_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectorNumberMeta = const VerificationMeta(
    'collectorNumber',
  );
  @override
  late final GeneratedColumn<String> collectorNumber = GeneratedColumn<String>(
    'collector_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _foilMeta = const VerificationMeta('foil');
  @override
  late final GeneratedColumn<int> foil = GeneratedColumn<int>(
    'foil',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NM'),
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceUsdMeta = const VerificationMeta(
    'priceUsd',
  );
  @override
  late final GeneratedColumn<double> priceUsd = GeneratedColumn<double>(
    'price_usd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUsdFoilMeta = const VerificationMeta(
    'priceUsdFoil',
  );
  @override
  late final GeneratedColumn<double> priceUsdFoil = GeneratedColumn<double>(
    'price_usd_foil',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceEurMeta = const VerificationMeta(
    'priceEur',
  );
  @override
  late final GeneratedColumn<double> priceEur = GeneratedColumn<double>(
    'price_eur',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceEurFoilMeta = const VerificationMeta(
    'priceEurFoil',
  );
  @override
  late final GeneratedColumn<double> priceEurFoil = GeneratedColumn<double>(
    'price_eur_foil',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUpdatedAtMeta = const VerificationMeta(
    'priceUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> priceUpdatedAt =
      GeneratedColumn<DateTime>(
        'price_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
    'rarity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageSmallMeta = const VerificationMeta(
    'imageSmall',
  );
  @override
  late final GeneratedColumn<String> imageSmall = GeneratedColumn<String>(
    'image_small',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scryfallId,
    name,
    setCode,
    collectorNumber,
    count,
    foil,
    condition,
    language,
    addedAt,
    priceUsd,
    priceUsdFoil,
    priceEur,
    priceEurFoil,
    priceUpdatedAt,
    notes,
    rarity,
    imageSmall,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('scryfall_id')) {
      context.handle(
        _scryfallIdMeta,
        scryfallId.isAcceptableOrUnknown(data['scryfall_id']!, _scryfallIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scryfallIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('set_code')) {
      context.handle(
        _setCodeMeta,
        setCode.isAcceptableOrUnknown(data['set_code']!, _setCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_setCodeMeta);
    }
    if (data.containsKey('collector_number')) {
      context.handle(
        _collectorNumberMeta,
        collectorNumber.isAcceptableOrUnknown(
          data['collector_number']!,
          _collectorNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectorNumberMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('foil')) {
      context.handle(
        _foilMeta,
        foil.isAcceptableOrUnknown(data['foil']!, _foilMeta),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(
        _priceUsdMeta,
        priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta),
      );
    }
    if (data.containsKey('price_usd_foil')) {
      context.handle(
        _priceUsdFoilMeta,
        priceUsdFoil.isAcceptableOrUnknown(
          data['price_usd_foil']!,
          _priceUsdFoilMeta,
        ),
      );
    }
    if (data.containsKey('price_eur')) {
      context.handle(
        _priceEurMeta,
        priceEur.isAcceptableOrUnknown(data['price_eur']!, _priceEurMeta),
      );
    }
    if (data.containsKey('price_eur_foil')) {
      context.handle(
        _priceEurFoilMeta,
        priceEurFoil.isAcceptableOrUnknown(
          data['price_eur_foil']!,
          _priceEurFoilMeta,
        ),
      );
    }
    if (data.containsKey('price_updated_at')) {
      context.handle(
        _priceUpdatedAtMeta,
        priceUpdatedAt.isAcceptableOrUnknown(
          data['price_updated_at']!,
          _priceUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('rarity')) {
      context.handle(
        _rarityMeta,
        rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta),
      );
    }
    if (data.containsKey('image_small')) {
      context.handle(
        _imageSmallMeta,
        imageSmall.isAcceptableOrUnknown(data['image_small']!, _imageSmallMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scryfallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scryfall_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      setCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code'],
      )!,
      collectorNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_number'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      foil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foil'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
      priceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd'],
      ),
      priceUsdFoil: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd_foil'],
      ),
      priceEur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_eur'],
      ),
      priceEurFoil: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_eur_foil'],
      ),
      priceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}price_updated_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      rarity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rarity'],
      ),
      imageSmall: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_small'],
      ),
    );
  }

  @override
  $CollectionTable createAlias(String alias) {
    return $CollectionTable(attachedDatabase, alias);
  }
}

class CollectionData extends DataClass implements Insertable<CollectionData> {
  final int id;
  final String scryfallId;
  final String name;
  final String setCode;
  final String collectorNumber;
  final int count;
  final int foil;
  final String condition;
  final String language;
  final DateTime addedAt;
  final double? priceUsd;
  final double? priceUsdFoil;
  final double? priceEur;
  final double? priceEurFoil;
  final DateTime? priceUpdatedAt;
  final String? notes;
  final String? rarity;
  final String? imageSmall;
  const CollectionData({
    required this.id,
    required this.scryfallId,
    required this.name,
    required this.setCode,
    required this.collectorNumber,
    required this.count,
    required this.foil,
    required this.condition,
    required this.language,
    required this.addedAt,
    this.priceUsd,
    this.priceUsdFoil,
    this.priceEur,
    this.priceEurFoil,
    this.priceUpdatedAt,
    this.notes,
    this.rarity,
    this.imageSmall,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['scryfall_id'] = Variable<String>(scryfallId);
    map['name'] = Variable<String>(name);
    map['set_code'] = Variable<String>(setCode);
    map['collector_number'] = Variable<String>(collectorNumber);
    map['count'] = Variable<int>(count);
    map['foil'] = Variable<int>(foil);
    map['condition'] = Variable<String>(condition);
    map['language'] = Variable<String>(language);
    map['added_at'] = Variable<DateTime>(addedAt);
    if (!nullToAbsent || priceUsd != null) {
      map['price_usd'] = Variable<double>(priceUsd);
    }
    if (!nullToAbsent || priceUsdFoil != null) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil);
    }
    if (!nullToAbsent || priceEur != null) {
      map['price_eur'] = Variable<double>(priceEur);
    }
    if (!nullToAbsent || priceEurFoil != null) {
      map['price_eur_foil'] = Variable<double>(priceEurFoil);
    }
    if (!nullToAbsent || priceUpdatedAt != null) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rarity != null) {
      map['rarity'] = Variable<String>(rarity);
    }
    if (!nullToAbsent || imageSmall != null) {
      map['image_small'] = Variable<String>(imageSmall);
    }
    return map;
  }

  CollectionCompanion toCompanion(bool nullToAbsent) {
    return CollectionCompanion(
      id: Value(id),
      scryfallId: Value(scryfallId),
      name: Value(name),
      setCode: Value(setCode),
      collectorNumber: Value(collectorNumber),
      count: Value(count),
      foil: Value(foil),
      condition: Value(condition),
      language: Value(language),
      addedAt: Value(addedAt),
      priceUsd: priceUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsd),
      priceUsdFoil: priceUsdFoil == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsdFoil),
      priceEur: priceEur == null && nullToAbsent
          ? const Value.absent()
          : Value(priceEur),
      priceEurFoil: priceEurFoil == null && nullToAbsent
          ? const Value.absent()
          : Value(priceEurFoil),
      priceUpdatedAt: priceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUpdatedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      rarity: rarity == null && nullToAbsent
          ? const Value.absent()
          : Value(rarity),
      imageSmall: imageSmall == null && nullToAbsent
          ? const Value.absent()
          : Value(imageSmall),
    );
  }

  factory CollectionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionData(
      id: serializer.fromJson<int>(json['id']),
      scryfallId: serializer.fromJson<String>(json['scryfallId']),
      name: serializer.fromJson<String>(json['name']),
      setCode: serializer.fromJson<String>(json['setCode']),
      collectorNumber: serializer.fromJson<String>(json['collectorNumber']),
      count: serializer.fromJson<int>(json['count']),
      foil: serializer.fromJson<int>(json['foil']),
      condition: serializer.fromJson<String>(json['condition']),
      language: serializer.fromJson<String>(json['language']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      priceUsd: serializer.fromJson<double?>(json['priceUsd']),
      priceUsdFoil: serializer.fromJson<double?>(json['priceUsdFoil']),
      priceEur: serializer.fromJson<double?>(json['priceEur']),
      priceEurFoil: serializer.fromJson<double?>(json['priceEurFoil']),
      priceUpdatedAt: serializer.fromJson<DateTime?>(json['priceUpdatedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
      rarity: serializer.fromJson<String?>(json['rarity']),
      imageSmall: serializer.fromJson<String?>(json['imageSmall']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scryfallId': serializer.toJson<String>(scryfallId),
      'name': serializer.toJson<String>(name),
      'setCode': serializer.toJson<String>(setCode),
      'collectorNumber': serializer.toJson<String>(collectorNumber),
      'count': serializer.toJson<int>(count),
      'foil': serializer.toJson<int>(foil),
      'condition': serializer.toJson<String>(condition),
      'language': serializer.toJson<String>(language),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'priceUsd': serializer.toJson<double?>(priceUsd),
      'priceUsdFoil': serializer.toJson<double?>(priceUsdFoil),
      'priceEur': serializer.toJson<double?>(priceEur),
      'priceEurFoil': serializer.toJson<double?>(priceEurFoil),
      'priceUpdatedAt': serializer.toJson<DateTime?>(priceUpdatedAt),
      'notes': serializer.toJson<String?>(notes),
      'rarity': serializer.toJson<String?>(rarity),
      'imageSmall': serializer.toJson<String?>(imageSmall),
    };
  }

  CollectionData copyWith({
    int? id,
    String? scryfallId,
    String? name,
    String? setCode,
    String? collectorNumber,
    int? count,
    int? foil,
    String? condition,
    String? language,
    DateTime? addedAt,
    Value<double?> priceUsd = const Value.absent(),
    Value<double?> priceUsdFoil = const Value.absent(),
    Value<double?> priceEur = const Value.absent(),
    Value<double?> priceEurFoil = const Value.absent(),
    Value<DateTime?> priceUpdatedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> rarity = const Value.absent(),
    Value<String?> imageSmall = const Value.absent(),
  }) => CollectionData(
    id: id ?? this.id,
    scryfallId: scryfallId ?? this.scryfallId,
    name: name ?? this.name,
    setCode: setCode ?? this.setCode,
    collectorNumber: collectorNumber ?? this.collectorNumber,
    count: count ?? this.count,
    foil: foil ?? this.foil,
    condition: condition ?? this.condition,
    language: language ?? this.language,
    addedAt: addedAt ?? this.addedAt,
    priceUsd: priceUsd.present ? priceUsd.value : this.priceUsd,
    priceUsdFoil: priceUsdFoil.present ? priceUsdFoil.value : this.priceUsdFoil,
    priceEur: priceEur.present ? priceEur.value : this.priceEur,
    priceEurFoil: priceEurFoil.present ? priceEurFoil.value : this.priceEurFoil,
    priceUpdatedAt: priceUpdatedAt.present
        ? priceUpdatedAt.value
        : this.priceUpdatedAt,
    notes: notes.present ? notes.value : this.notes,
    rarity: rarity.present ? rarity.value : this.rarity,
    imageSmall: imageSmall.present ? imageSmall.value : this.imageSmall,
  );
  CollectionData copyWithCompanion(CollectionCompanion data) {
    return CollectionData(
      id: data.id.present ? data.id.value : this.id,
      scryfallId: data.scryfallId.present
          ? data.scryfallId.value
          : this.scryfallId,
      name: data.name.present ? data.name.value : this.name,
      setCode: data.setCode.present ? data.setCode.value : this.setCode,
      collectorNumber: data.collectorNumber.present
          ? data.collectorNumber.value
          : this.collectorNumber,
      count: data.count.present ? data.count.value : this.count,
      foil: data.foil.present ? data.foil.value : this.foil,
      condition: data.condition.present ? data.condition.value : this.condition,
      language: data.language.present ? data.language.value : this.language,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      priceUsdFoil: data.priceUsdFoil.present
          ? data.priceUsdFoil.value
          : this.priceUsdFoil,
      priceEur: data.priceEur.present ? data.priceEur.value : this.priceEur,
      priceEurFoil: data.priceEurFoil.present
          ? data.priceEurFoil.value
          : this.priceEurFoil,
      priceUpdatedAt: data.priceUpdatedAt.present
          ? data.priceUpdatedAt.value
          : this.priceUpdatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      imageSmall: data.imageSmall.present
          ? data.imageSmall.value
          : this.imageSmall,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionData(')
          ..write('id: $id, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('name: $name, ')
          ..write('setCode: $setCode, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('count: $count, ')
          ..write('foil: $foil, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('addedAt: $addedAt, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('priceEur: $priceEur, ')
          ..write('priceEurFoil: $priceEurFoil, ')
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('notes: $notes, ')
          ..write('rarity: $rarity, ')
          ..write('imageSmall: $imageSmall')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scryfallId,
    name,
    setCode,
    collectorNumber,
    count,
    foil,
    condition,
    language,
    addedAt,
    priceUsd,
    priceUsdFoil,
    priceEur,
    priceEurFoil,
    priceUpdatedAt,
    notes,
    rarity,
    imageSmall,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionData &&
          other.id == this.id &&
          other.scryfallId == this.scryfallId &&
          other.name == this.name &&
          other.setCode == this.setCode &&
          other.collectorNumber == this.collectorNumber &&
          other.count == this.count &&
          other.foil == this.foil &&
          other.condition == this.condition &&
          other.language == this.language &&
          other.addedAt == this.addedAt &&
          other.priceUsd == this.priceUsd &&
          other.priceUsdFoil == this.priceUsdFoil &&
          other.priceEur == this.priceEur &&
          other.priceEurFoil == this.priceEurFoil &&
          other.priceUpdatedAt == this.priceUpdatedAt &&
          other.notes == this.notes &&
          other.rarity == this.rarity &&
          other.imageSmall == this.imageSmall);
}

class CollectionCompanion extends UpdateCompanion<CollectionData> {
  final Value<int> id;
  final Value<String> scryfallId;
  final Value<String> name;
  final Value<String> setCode;
  final Value<String> collectorNumber;
  final Value<int> count;
  final Value<int> foil;
  final Value<String> condition;
  final Value<String> language;
  final Value<DateTime> addedAt;
  final Value<double?> priceUsd;
  final Value<double?> priceUsdFoil;
  final Value<double?> priceEur;
  final Value<double?> priceEurFoil;
  final Value<DateTime?> priceUpdatedAt;
  final Value<String?> notes;
  final Value<String?> rarity;
  final Value<String?> imageSmall;
  const CollectionCompanion({
    this.id = const Value.absent(),
    this.scryfallId = const Value.absent(),
    this.name = const Value.absent(),
    this.setCode = const Value.absent(),
    this.collectorNumber = const Value.absent(),
    this.count = const Value.absent(),
    this.foil = const Value.absent(),
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.priceEur = const Value.absent(),
    this.priceEurFoil = const Value.absent(),
    this.priceUpdatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rarity = const Value.absent(),
    this.imageSmall = const Value.absent(),
  });
  CollectionCompanion.insert({
    this.id = const Value.absent(),
    required String scryfallId,
    required String name,
    required String setCode,
    required String collectorNumber,
    this.count = const Value.absent(),
    this.foil = const Value.absent(),
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    required DateTime addedAt,
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.priceEur = const Value.absent(),
    this.priceEurFoil = const Value.absent(),
    this.priceUpdatedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.rarity = const Value.absent(),
    this.imageSmall = const Value.absent(),
  }) : scryfallId = Value(scryfallId),
       name = Value(name),
       setCode = Value(setCode),
       collectorNumber = Value(collectorNumber),
       addedAt = Value(addedAt);
  static Insertable<CollectionData> custom({
    Expression<int>? id,
    Expression<String>? scryfallId,
    Expression<String>? name,
    Expression<String>? setCode,
    Expression<String>? collectorNumber,
    Expression<int>? count,
    Expression<int>? foil,
    Expression<String>? condition,
    Expression<String>? language,
    Expression<DateTime>? addedAt,
    Expression<double>? priceUsd,
    Expression<double>? priceUsdFoil,
    Expression<double>? priceEur,
    Expression<double>? priceEurFoil,
    Expression<DateTime>? priceUpdatedAt,
    Expression<String>? notes,
    Expression<String>? rarity,
    Expression<String>? imageSmall,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scryfallId != null) 'scryfall_id': scryfallId,
      if (name != null) 'name': name,
      if (setCode != null) 'set_code': setCode,
      if (collectorNumber != null) 'collector_number': collectorNumber,
      if (count != null) 'count': count,
      if (foil != null) 'foil': foil,
      if (condition != null) 'condition': condition,
      if (language != null) 'language': language,
      if (addedAt != null) 'added_at': addedAt,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (priceUsdFoil != null) 'price_usd_foil': priceUsdFoil,
      if (priceEur != null) 'price_eur': priceEur,
      if (priceEurFoil != null) 'price_eur_foil': priceEurFoil,
      if (priceUpdatedAt != null) 'price_updated_at': priceUpdatedAt,
      if (notes != null) 'notes': notes,
      if (rarity != null) 'rarity': rarity,
      if (imageSmall != null) 'image_small': imageSmall,
    });
  }

  CollectionCompanion copyWith({
    Value<int>? id,
    Value<String>? scryfallId,
    Value<String>? name,
    Value<String>? setCode,
    Value<String>? collectorNumber,
    Value<int>? count,
    Value<int>? foil,
    Value<String>? condition,
    Value<String>? language,
    Value<DateTime>? addedAt,
    Value<double?>? priceUsd,
    Value<double?>? priceUsdFoil,
    Value<double?>? priceEur,
    Value<double?>? priceEurFoil,
    Value<DateTime?>? priceUpdatedAt,
    Value<String?>? notes,
    Value<String?>? rarity,
    Value<String?>? imageSmall,
  }) {
    return CollectionCompanion(
      id: id ?? this.id,
      scryfallId: scryfallId ?? this.scryfallId,
      name: name ?? this.name,
      setCode: setCode ?? this.setCode,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      count: count ?? this.count,
      foil: foil ?? this.foil,
      condition: condition ?? this.condition,
      language: language ?? this.language,
      addedAt: addedAt ?? this.addedAt,
      priceUsd: priceUsd ?? this.priceUsd,
      priceUsdFoil: priceUsdFoil ?? this.priceUsdFoil,
      priceEur: priceEur ?? this.priceEur,
      priceEurFoil: priceEurFoil ?? this.priceEurFoil,
      priceUpdatedAt: priceUpdatedAt ?? this.priceUpdatedAt,
      notes: notes ?? this.notes,
      rarity: rarity ?? this.rarity,
      imageSmall: imageSmall ?? this.imageSmall,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scryfallId.present) {
      map['scryfall_id'] = Variable<String>(scryfallId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (setCode.present) {
      map['set_code'] = Variable<String>(setCode.value);
    }
    if (collectorNumber.present) {
      map['collector_number'] = Variable<String>(collectorNumber.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (foil.present) {
      map['foil'] = Variable<int>(foil.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (priceUsdFoil.present) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil.value);
    }
    if (priceEur.present) {
      map['price_eur'] = Variable<double>(priceEur.value);
    }
    if (priceEurFoil.present) {
      map['price_eur_foil'] = Variable<double>(priceEurFoil.value);
    }
    if (priceUpdatedAt.present) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (imageSmall.present) {
      map['image_small'] = Variable<String>(imageSmall.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionCompanion(')
          ..write('id: $id, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('name: $name, ')
          ..write('setCode: $setCode, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('count: $count, ')
          ..write('foil: $foil, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('addedAt: $addedAt, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('priceEur: $priceEur, ')
          ..write('priceEurFoil: $priceEurFoil, ')
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('notes: $notes, ')
          ..write('rarity: $rarity, ')
          ..write('imageSmall: $imageSmall')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CollectionTable collection = $CollectionTable(this);
  late final CollectionDao collectionDao = CollectionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [collection];
}

typedef $$CollectionTableCreateCompanionBuilder =
    CollectionCompanion Function({
      Value<int> id,
      required String scryfallId,
      required String name,
      required String setCode,
      required String collectorNumber,
      Value<int> count,
      Value<int> foil,
      Value<String> condition,
      Value<String> language,
      required DateTime addedAt,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<double?> priceEur,
      Value<double?> priceEurFoil,
      Value<DateTime?> priceUpdatedAt,
      Value<String?> notes,
      Value<String?> rarity,
      Value<String?> imageSmall,
    });
typedef $$CollectionTableUpdateCompanionBuilder =
    CollectionCompanion Function({
      Value<int> id,
      Value<String> scryfallId,
      Value<String> name,
      Value<String> setCode,
      Value<String> collectorNumber,
      Value<int> count,
      Value<int> foil,
      Value<String> condition,
      Value<String> language,
      Value<DateTime> addedAt,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<double?> priceEur,
      Value<double?> priceEurFoil,
      Value<DateTime?> priceUpdatedAt,
      Value<String?> notes,
      Value<String?> rarity,
      Value<String?> imageSmall,
    });

class $$CollectionTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionTable> {
  $$CollectionTableFilterComposer({
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

  ColumnFilters<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foil => $composableBuilder(
    column: $table.foil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceEur => $composableBuilder(
    column: $table.priceEur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageSmall => $composableBuilder(
    column: $table.imageSmall,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionTable> {
  $$CollectionTableOrderingComposer({
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

  ColumnOrderings<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foil => $composableBuilder(
    column: $table.foil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceEur => $composableBuilder(
    column: $table.priceEur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageSmall => $composableBuilder(
    column: $table.imageSmall,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionTable> {
  $$CollectionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get setCode =>
      $composableBuilder(column: $table.setCode, builder: (column) => column);

  GeneratedColumn<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<int> get foil =>
      $composableBuilder(column: $table.foil, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceEur =>
      $composableBuilder(column: $table.priceEur, builder: (column) => column);

  GeneratedColumn<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<String> get imageSmall => $composableBuilder(
    column: $table.imageSmall,
    builder: (column) => column,
  );
}

class $$CollectionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionTable,
          CollectionData,
          $$CollectionTableFilterComposer,
          $$CollectionTableOrderingComposer,
          $$CollectionTableAnnotationComposer,
          $$CollectionTableCreateCompanionBuilder,
          $$CollectionTableUpdateCompanionBuilder,
          (
            CollectionData,
            BaseReferences<_$AppDatabase, $CollectionTable, CollectionData>,
          ),
          CollectionData,
          PrefetchHooks Function()
        > {
  $$CollectionTableTableManager(_$AppDatabase db, $CollectionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> scryfallId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> setCode = const Value.absent(),
                Value<String> collectorNumber = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> foil = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<double?> priceEur = const Value.absent(),
                Value<double?> priceEurFoil = const Value.absent(),
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> rarity = const Value.absent(),
                Value<String?> imageSmall = const Value.absent(),
              }) => CollectionCompanion(
                id: id,
                scryfallId: scryfallId,
                name: name,
                setCode: setCode,
                collectorNumber: collectorNumber,
                count: count,
                foil: foil,
                condition: condition,
                language: language,
                addedAt: addedAt,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                priceEur: priceEur,
                priceEurFoil: priceEurFoil,
                priceUpdatedAt: priceUpdatedAt,
                notes: notes,
                rarity: rarity,
                imageSmall: imageSmall,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String scryfallId,
                required String name,
                required String setCode,
                required String collectorNumber,
                Value<int> count = const Value.absent(),
                Value<int> foil = const Value.absent(),
                Value<String> condition = const Value.absent(),
                Value<String> language = const Value.absent(),
                required DateTime addedAt,
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<double?> priceEur = const Value.absent(),
                Value<double?> priceEurFoil = const Value.absent(),
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> rarity = const Value.absent(),
                Value<String?> imageSmall = const Value.absent(),
              }) => CollectionCompanion.insert(
                id: id,
                scryfallId: scryfallId,
                name: name,
                setCode: setCode,
                collectorNumber: collectorNumber,
                count: count,
                foil: foil,
                condition: condition,
                language: language,
                addedAt: addedAt,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                priceEur: priceEur,
                priceEurFoil: priceEurFoil,
                priceUpdatedAt: priceUpdatedAt,
                notes: notes,
                rarity: rarity,
                imageSmall: imageSmall,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionTable,
      CollectionData,
      $$CollectionTableFilterComposer,
      $$CollectionTableOrderingComposer,
      $$CollectionTableAnnotationComposer,
      $$CollectionTableCreateCompanionBuilder,
      $$CollectionTableUpdateCompanionBuilder,
      (
        CollectionData,
        BaseReferences<_$AppDatabase, $CollectionTable, CollectionData>,
      ),
      CollectionData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CollectionTableTableManager get collection =>
      $$CollectionTableTableManager(_db, _db.collection);
}
