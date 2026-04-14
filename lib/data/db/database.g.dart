// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScansTable extends Scans with TableInfo<$ScansTable, Scan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawNameMeta = const VerificationMeta(
    'rawName',
  );
  @override
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
    'raw_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawSetCollectorMeta = const VerificationMeta(
    'rawSetCollector',
  );
  @override
  late final GeneratedColumn<String> rawSetCollector = GeneratedColumn<String>(
    'raw_set_collector',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchedScryfallIdMeta = const VerificationMeta(
    'matchedScryfallId',
  );
  @override
  late final GeneratedColumn<String> matchedScryfallId =
      GeneratedColumn<String>(
        'matched_scryfall_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _matchedNameMeta = const VerificationMeta(
    'matchedName',
  );
  @override
  late final GeneratedColumn<String> matchedName = GeneratedColumn<String>(
    'matched_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchedSetMeta = const VerificationMeta(
    'matchedSet',
  );
  @override
  late final GeneratedColumn<String> matchedSet = GeneratedColumn<String>(
    'matched_set',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _matchedCollectorNumberMeta =
      const VerificationMeta('matchedCollectorNumber');
  @override
  late final GeneratedColumn<String> matchedCollectorNumber =
      GeneratedColumn<String>(
        'matched_collector_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _foilGuessMeta = const VerificationMeta(
    'foilGuess',
  );
  @override
  late final GeneratedColumn<int> foilGuess = GeneratedColumn<int>(
    'foil_guess',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _cropImagePathMeta = const VerificationMeta(
    'cropImagePath',
  );
  @override
  late final GeneratedColumn<String> cropImagePath = GeneratedColumn<String>(
    'crop_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    capturedAt,
    rawName,
    rawSetCollector,
    matchedScryfallId,
    matchedName,
    matchedSet,
    matchedCollectorNumber,
    confidence,
    foilGuess,
    cropImagePath,
    priceUsd,
    priceUsdFoil,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(
        _rawNameMeta,
        rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('raw_set_collector')) {
      context.handle(
        _rawSetCollectorMeta,
        rawSetCollector.isAcceptableOrUnknown(
          data['raw_set_collector']!,
          _rawSetCollectorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawSetCollectorMeta);
    }
    if (data.containsKey('matched_scryfall_id')) {
      context.handle(
        _matchedScryfallIdMeta,
        matchedScryfallId.isAcceptableOrUnknown(
          data['matched_scryfall_id']!,
          _matchedScryfallIdMeta,
        ),
      );
    }
    if (data.containsKey('matched_name')) {
      context.handle(
        _matchedNameMeta,
        matchedName.isAcceptableOrUnknown(
          data['matched_name']!,
          _matchedNameMeta,
        ),
      );
    }
    if (data.containsKey('matched_set')) {
      context.handle(
        _matchedSetMeta,
        matchedSet.isAcceptableOrUnknown(data['matched_set']!, _matchedSetMeta),
      );
    }
    if (data.containsKey('matched_collector_number')) {
      context.handle(
        _matchedCollectorNumberMeta,
        matchedCollectorNumber.isAcceptableOrUnknown(
          data['matched_collector_number']!,
          _matchedCollectorNumberMeta,
        ),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('foil_guess')) {
      context.handle(
        _foilGuessMeta,
        foilGuess.isAcceptableOrUnknown(data['foil_guess']!, _foilGuessMeta),
      );
    }
    if (data.containsKey('crop_image_path')) {
      context.handle(
        _cropImagePathMeta,
        cropImagePath.isAcceptableOrUnknown(
          data['crop_image_path']!,
          _cropImagePathMeta,
        ),
      );
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
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      rawName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_name'],
      )!,
      rawSetCollector: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_set_collector'],
      )!,
      matchedScryfallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_scryfall_id'],
      ),
      matchedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_name'],
      ),
      matchedSet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_set'],
      ),
      matchedCollectorNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_collector_number'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      foilGuess: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foil_guess'],
      )!,
      cropImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}crop_image_path'],
      ),
      priceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd'],
      ),
      priceUsdFoil: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd_foil'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ScansTable createAlias(String alias) {
    return $ScansTable(attachedDatabase, alias);
  }
}

class Scan extends DataClass implements Insertable<Scan> {
  final int id;
  final DateTime capturedAt;
  final String rawName;
  final String rawSetCollector;
  final String? matchedScryfallId;
  final String? matchedName;
  final String? matchedSet;
  final String? matchedCollectorNumber;
  final double confidence;
  final int foilGuess;
  final String? cropImagePath;
  final double? priceUsd;
  final double? priceUsdFoil;
  final String status;
  const Scan({
    required this.id,
    required this.capturedAt,
    required this.rawName,
    required this.rawSetCollector,
    this.matchedScryfallId,
    this.matchedName,
    this.matchedSet,
    this.matchedCollectorNumber,
    required this.confidence,
    required this.foilGuess,
    this.cropImagePath,
    this.priceUsd,
    this.priceUsdFoil,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['raw_name'] = Variable<String>(rawName);
    map['raw_set_collector'] = Variable<String>(rawSetCollector);
    if (!nullToAbsent || matchedScryfallId != null) {
      map['matched_scryfall_id'] = Variable<String>(matchedScryfallId);
    }
    if (!nullToAbsent || matchedName != null) {
      map['matched_name'] = Variable<String>(matchedName);
    }
    if (!nullToAbsent || matchedSet != null) {
      map['matched_set'] = Variable<String>(matchedSet);
    }
    if (!nullToAbsent || matchedCollectorNumber != null) {
      map['matched_collector_number'] = Variable<String>(
        matchedCollectorNumber,
      );
    }
    map['confidence'] = Variable<double>(confidence);
    map['foil_guess'] = Variable<int>(foilGuess);
    if (!nullToAbsent || cropImagePath != null) {
      map['crop_image_path'] = Variable<String>(cropImagePath);
    }
    if (!nullToAbsent || priceUsd != null) {
      map['price_usd'] = Variable<double>(priceUsd);
    }
    if (!nullToAbsent || priceUsdFoil != null) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  ScansCompanion toCompanion(bool nullToAbsent) {
    return ScansCompanion(
      id: Value(id),
      capturedAt: Value(capturedAt),
      rawName: Value(rawName),
      rawSetCollector: Value(rawSetCollector),
      matchedScryfallId: matchedScryfallId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedScryfallId),
      matchedName: matchedName == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedName),
      matchedSet: matchedSet == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedSet),
      matchedCollectorNumber: matchedCollectorNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedCollectorNumber),
      confidence: Value(confidence),
      foilGuess: Value(foilGuess),
      cropImagePath: cropImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(cropImagePath),
      priceUsd: priceUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsd),
      priceUsdFoil: priceUsdFoil == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsdFoil),
      status: Value(status),
    );
  }

  factory Scan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scan(
      id: serializer.fromJson<int>(json['id']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      rawName: serializer.fromJson<String>(json['rawName']),
      rawSetCollector: serializer.fromJson<String>(json['rawSetCollector']),
      matchedScryfallId: serializer.fromJson<String?>(
        json['matchedScryfallId'],
      ),
      matchedName: serializer.fromJson<String?>(json['matchedName']),
      matchedSet: serializer.fromJson<String?>(json['matchedSet']),
      matchedCollectorNumber: serializer.fromJson<String?>(
        json['matchedCollectorNumber'],
      ),
      confidence: serializer.fromJson<double>(json['confidence']),
      foilGuess: serializer.fromJson<int>(json['foilGuess']),
      cropImagePath: serializer.fromJson<String?>(json['cropImagePath']),
      priceUsd: serializer.fromJson<double?>(json['priceUsd']),
      priceUsdFoil: serializer.fromJson<double?>(json['priceUsdFoil']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'rawName': serializer.toJson<String>(rawName),
      'rawSetCollector': serializer.toJson<String>(rawSetCollector),
      'matchedScryfallId': serializer.toJson<String?>(matchedScryfallId),
      'matchedName': serializer.toJson<String?>(matchedName),
      'matchedSet': serializer.toJson<String?>(matchedSet),
      'matchedCollectorNumber': serializer.toJson<String?>(
        matchedCollectorNumber,
      ),
      'confidence': serializer.toJson<double>(confidence),
      'foilGuess': serializer.toJson<int>(foilGuess),
      'cropImagePath': serializer.toJson<String?>(cropImagePath),
      'priceUsd': serializer.toJson<double?>(priceUsd),
      'priceUsdFoil': serializer.toJson<double?>(priceUsdFoil),
      'status': serializer.toJson<String>(status),
    };
  }

  Scan copyWith({
    int? id,
    DateTime? capturedAt,
    String? rawName,
    String? rawSetCollector,
    Value<String?> matchedScryfallId = const Value.absent(),
    Value<String?> matchedName = const Value.absent(),
    Value<String?> matchedSet = const Value.absent(),
    Value<String?> matchedCollectorNumber = const Value.absent(),
    double? confidence,
    int? foilGuess,
    Value<String?> cropImagePath = const Value.absent(),
    Value<double?> priceUsd = const Value.absent(),
    Value<double?> priceUsdFoil = const Value.absent(),
    String? status,
  }) => Scan(
    id: id ?? this.id,
    capturedAt: capturedAt ?? this.capturedAt,
    rawName: rawName ?? this.rawName,
    rawSetCollector: rawSetCollector ?? this.rawSetCollector,
    matchedScryfallId: matchedScryfallId.present
        ? matchedScryfallId.value
        : this.matchedScryfallId,
    matchedName: matchedName.present ? matchedName.value : this.matchedName,
    matchedSet: matchedSet.present ? matchedSet.value : this.matchedSet,
    matchedCollectorNumber: matchedCollectorNumber.present
        ? matchedCollectorNumber.value
        : this.matchedCollectorNumber,
    confidence: confidence ?? this.confidence,
    foilGuess: foilGuess ?? this.foilGuess,
    cropImagePath: cropImagePath.present
        ? cropImagePath.value
        : this.cropImagePath,
    priceUsd: priceUsd.present ? priceUsd.value : this.priceUsd,
    priceUsdFoil: priceUsdFoil.present ? priceUsdFoil.value : this.priceUsdFoil,
    status: status ?? this.status,
  );
  Scan copyWithCompanion(ScansCompanion data) {
    return Scan(
      id: data.id.present ? data.id.value : this.id,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      rawSetCollector: data.rawSetCollector.present
          ? data.rawSetCollector.value
          : this.rawSetCollector,
      matchedScryfallId: data.matchedScryfallId.present
          ? data.matchedScryfallId.value
          : this.matchedScryfallId,
      matchedName: data.matchedName.present
          ? data.matchedName.value
          : this.matchedName,
      matchedSet: data.matchedSet.present
          ? data.matchedSet.value
          : this.matchedSet,
      matchedCollectorNumber: data.matchedCollectorNumber.present
          ? data.matchedCollectorNumber.value
          : this.matchedCollectorNumber,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      foilGuess: data.foilGuess.present ? data.foilGuess.value : this.foilGuess,
      cropImagePath: data.cropImagePath.present
          ? data.cropImagePath.value
          : this.cropImagePath,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      priceUsdFoil: data.priceUsdFoil.present
          ? data.priceUsdFoil.value
          : this.priceUsdFoil,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scan(')
          ..write('id: $id, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rawName: $rawName, ')
          ..write('rawSetCollector: $rawSetCollector, ')
          ..write('matchedScryfallId: $matchedScryfallId, ')
          ..write('matchedName: $matchedName, ')
          ..write('matchedSet: $matchedSet, ')
          ..write('matchedCollectorNumber: $matchedCollectorNumber, ')
          ..write('confidence: $confidence, ')
          ..write('foilGuess: $foilGuess, ')
          ..write('cropImagePath: $cropImagePath, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    capturedAt,
    rawName,
    rawSetCollector,
    matchedScryfallId,
    matchedName,
    matchedSet,
    matchedCollectorNumber,
    confidence,
    foilGuess,
    cropImagePath,
    priceUsd,
    priceUsdFoil,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scan &&
          other.id == this.id &&
          other.capturedAt == this.capturedAt &&
          other.rawName == this.rawName &&
          other.rawSetCollector == this.rawSetCollector &&
          other.matchedScryfallId == this.matchedScryfallId &&
          other.matchedName == this.matchedName &&
          other.matchedSet == this.matchedSet &&
          other.matchedCollectorNumber == this.matchedCollectorNumber &&
          other.confidence == this.confidence &&
          other.foilGuess == this.foilGuess &&
          other.cropImagePath == this.cropImagePath &&
          other.priceUsd == this.priceUsd &&
          other.priceUsdFoil == this.priceUsdFoil &&
          other.status == this.status);
}

class ScansCompanion extends UpdateCompanion<Scan> {
  final Value<int> id;
  final Value<DateTime> capturedAt;
  final Value<String> rawName;
  final Value<String> rawSetCollector;
  final Value<String?> matchedScryfallId;
  final Value<String?> matchedName;
  final Value<String?> matchedSet;
  final Value<String?> matchedCollectorNumber;
  final Value<double> confidence;
  final Value<int> foilGuess;
  final Value<String?> cropImagePath;
  final Value<double?> priceUsd;
  final Value<double?> priceUsdFoil;
  final Value<String> status;
  const ScansCompanion({
    this.id = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rawName = const Value.absent(),
    this.rawSetCollector = const Value.absent(),
    this.matchedScryfallId = const Value.absent(),
    this.matchedName = const Value.absent(),
    this.matchedSet = const Value.absent(),
    this.matchedCollectorNumber = const Value.absent(),
    this.confidence = const Value.absent(),
    this.foilGuess = const Value.absent(),
    this.cropImagePath = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.status = const Value.absent(),
  });
  ScansCompanion.insert({
    this.id = const Value.absent(),
    required DateTime capturedAt,
    required String rawName,
    required String rawSetCollector,
    this.matchedScryfallId = const Value.absent(),
    this.matchedName = const Value.absent(),
    this.matchedSet = const Value.absent(),
    this.matchedCollectorNumber = const Value.absent(),
    this.confidence = const Value.absent(),
    this.foilGuess = const Value.absent(),
    this.cropImagePath = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.status = const Value.absent(),
  }) : capturedAt = Value(capturedAt),
       rawName = Value(rawName),
       rawSetCollector = Value(rawSetCollector);
  static Insertable<Scan> custom({
    Expression<int>? id,
    Expression<DateTime>? capturedAt,
    Expression<String>? rawName,
    Expression<String>? rawSetCollector,
    Expression<String>? matchedScryfallId,
    Expression<String>? matchedName,
    Expression<String>? matchedSet,
    Expression<String>? matchedCollectorNumber,
    Expression<double>? confidence,
    Expression<int>? foilGuess,
    Expression<String>? cropImagePath,
    Expression<double>? priceUsd,
    Expression<double>? priceUsdFoil,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rawName != null) 'raw_name': rawName,
      if (rawSetCollector != null) 'raw_set_collector': rawSetCollector,
      if (matchedScryfallId != null) 'matched_scryfall_id': matchedScryfallId,
      if (matchedName != null) 'matched_name': matchedName,
      if (matchedSet != null) 'matched_set': matchedSet,
      if (matchedCollectorNumber != null)
        'matched_collector_number': matchedCollectorNumber,
      if (confidence != null) 'confidence': confidence,
      if (foilGuess != null) 'foil_guess': foilGuess,
      if (cropImagePath != null) 'crop_image_path': cropImagePath,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (priceUsdFoil != null) 'price_usd_foil': priceUsdFoil,
      if (status != null) 'status': status,
    });
  }

  ScansCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? capturedAt,
    Value<String>? rawName,
    Value<String>? rawSetCollector,
    Value<String?>? matchedScryfallId,
    Value<String?>? matchedName,
    Value<String?>? matchedSet,
    Value<String?>? matchedCollectorNumber,
    Value<double>? confidence,
    Value<int>? foilGuess,
    Value<String?>? cropImagePath,
    Value<double?>? priceUsd,
    Value<double?>? priceUsdFoil,
    Value<String>? status,
  }) {
    return ScansCompanion(
      id: id ?? this.id,
      capturedAt: capturedAt ?? this.capturedAt,
      rawName: rawName ?? this.rawName,
      rawSetCollector: rawSetCollector ?? this.rawSetCollector,
      matchedScryfallId: matchedScryfallId ?? this.matchedScryfallId,
      matchedName: matchedName ?? this.matchedName,
      matchedSet: matchedSet ?? this.matchedSet,
      matchedCollectorNumber:
          matchedCollectorNumber ?? this.matchedCollectorNumber,
      confidence: confidence ?? this.confidence,
      foilGuess: foilGuess ?? this.foilGuess,
      cropImagePath: cropImagePath ?? this.cropImagePath,
      priceUsd: priceUsd ?? this.priceUsd,
      priceUsdFoil: priceUsdFoil ?? this.priceUsdFoil,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (rawSetCollector.present) {
      map['raw_set_collector'] = Variable<String>(rawSetCollector.value);
    }
    if (matchedScryfallId.present) {
      map['matched_scryfall_id'] = Variable<String>(matchedScryfallId.value);
    }
    if (matchedName.present) {
      map['matched_name'] = Variable<String>(matchedName.value);
    }
    if (matchedSet.present) {
      map['matched_set'] = Variable<String>(matchedSet.value);
    }
    if (matchedCollectorNumber.present) {
      map['matched_collector_number'] = Variable<String>(
        matchedCollectorNumber.value,
      );
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (foilGuess.present) {
      map['foil_guess'] = Variable<int>(foilGuess.value);
    }
    if (cropImagePath.present) {
      map['crop_image_path'] = Variable<String>(cropImagePath.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (priceUsdFoil.present) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScansCompanion(')
          ..write('id: $id, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rawName: $rawName, ')
          ..write('rawSetCollector: $rawSetCollector, ')
          ..write('matchedScryfallId: $matchedScryfallId, ')
          ..write('matchedName: $matchedName, ')
          ..write('matchedSet: $matchedSet, ')
          ..write('matchedCollectorNumber: $matchedCollectorNumber, ')
          ..write('confidence: $confidence, ')
          ..write('foilGuess: $foilGuess, ')
          ..write('cropImagePath: $cropImagePath, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

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
    priceUpdatedAt,
    notes,
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
      priceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}price_updated_at'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
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
  final DateTime? priceUpdatedAt;
  final String? notes;
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
    this.priceUpdatedAt,
    this.notes,
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
    if (!nullToAbsent || priceUpdatedAt != null) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
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
      priceUpdatedAt: priceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUpdatedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
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
      priceUpdatedAt: serializer.fromJson<DateTime?>(json['priceUpdatedAt']),
      notes: serializer.fromJson<String?>(json['notes']),
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
      'priceUpdatedAt': serializer.toJson<DateTime?>(priceUpdatedAt),
      'notes': serializer.toJson<String?>(notes),
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
    Value<DateTime?> priceUpdatedAt = const Value.absent(),
    Value<String?> notes = const Value.absent(),
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
    priceUpdatedAt: priceUpdatedAt.present
        ? priceUpdatedAt.value
        : this.priceUpdatedAt,
    notes: notes.present ? notes.value : this.notes,
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
      priceUpdatedAt: data.priceUpdatedAt.present
          ? data.priceUpdatedAt.value
          : this.priceUpdatedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
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
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('notes: $notes')
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
    priceUpdatedAt,
    notes,
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
          other.priceUpdatedAt == this.priceUpdatedAt &&
          other.notes == this.notes);
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
  final Value<DateTime?> priceUpdatedAt;
  final Value<String?> notes;
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
    this.priceUpdatedAt = const Value.absent(),
    this.notes = const Value.absent(),
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
    this.priceUpdatedAt = const Value.absent(),
    this.notes = const Value.absent(),
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
    Expression<DateTime>? priceUpdatedAt,
    Expression<String>? notes,
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
      if (priceUpdatedAt != null) 'price_updated_at': priceUpdatedAt,
      if (notes != null) 'notes': notes,
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
    Value<DateTime?>? priceUpdatedAt,
    Value<String?>? notes,
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
      priceUpdatedAt: priceUpdatedAt ?? this.priceUpdatedAt,
      notes: notes ?? this.notes,
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
    if (priceUpdatedAt.present) {
      map['price_updated_at'] = Variable<DateTime>(priceUpdatedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
          ..write('priceUpdatedAt: $priceUpdatedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScansTable scans = $ScansTable(this);
  late final $CollectionTable collection = $CollectionTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [scans, collection];
}

typedef $$ScansTableCreateCompanionBuilder =
    ScansCompanion Function({
      Value<int> id,
      required DateTime capturedAt,
      required String rawName,
      required String rawSetCollector,
      Value<String?> matchedScryfallId,
      Value<String?> matchedName,
      Value<String?> matchedSet,
      Value<String?> matchedCollectorNumber,
      Value<double> confidence,
      Value<int> foilGuess,
      Value<String?> cropImagePath,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<String> status,
    });
typedef $$ScansTableUpdateCompanionBuilder =
    ScansCompanion Function({
      Value<int> id,
      Value<DateTime> capturedAt,
      Value<String> rawName,
      Value<String> rawSetCollector,
      Value<String?> matchedScryfallId,
      Value<String?> matchedName,
      Value<String?> matchedSet,
      Value<String?> matchedCollectorNumber,
      Value<double> confidence,
      Value<int> foilGuess,
      Value<String?> cropImagePath,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<String> status,
    });

class $$ScansTableFilterComposer extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableFilterComposer({
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

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSetCollector => $composableBuilder(
    column: $table.rawSetCollector,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedScryfallId => $composableBuilder(
    column: $table.matchedScryfallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedName => $composableBuilder(
    column: $table.matchedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedSet => $composableBuilder(
    column: $table.matchedSet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchedCollectorNumber => $composableBuilder(
    column: $table.matchedCollectorNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foilGuess => $composableBuilder(
    column: $table.foilGuess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cropImagePath => $composableBuilder(
    column: $table.cropImagePath,
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

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScansTableOrderingComposer
    extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableOrderingComposer({
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

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSetCollector => $composableBuilder(
    column: $table.rawSetCollector,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedScryfallId => $composableBuilder(
    column: $table.matchedScryfallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedName => $composableBuilder(
    column: $table.matchedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedSet => $composableBuilder(
    column: $table.matchedSet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchedCollectorNumber => $composableBuilder(
    column: $table.matchedCollectorNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foilGuess => $composableBuilder(
    column: $table.foilGuess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cropImagePath => $composableBuilder(
    column: $table.cropImagePath,
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

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScansTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScansTable> {
  $$ScansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<String> get rawSetCollector => $composableBuilder(
    column: $table.rawSetCollector,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchedScryfallId => $composableBuilder(
    column: $table.matchedScryfallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchedName => $composableBuilder(
    column: $table.matchedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchedSet => $composableBuilder(
    column: $table.matchedSet,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchedCollectorNumber => $composableBuilder(
    column: $table.matchedCollectorNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get foilGuess =>
      $composableBuilder(column: $table.foilGuess, builder: (column) => column);

  GeneratedColumn<String> get cropImagePath => $composableBuilder(
    column: $table.cropImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ScansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScansTable,
          Scan,
          $$ScansTableFilterComposer,
          $$ScansTableOrderingComposer,
          $$ScansTableAnnotationComposer,
          $$ScansTableCreateCompanionBuilder,
          $$ScansTableUpdateCompanionBuilder,
          (Scan, BaseReferences<_$AppDatabase, $ScansTable, Scan>),
          Scan,
          PrefetchHooks Function()
        > {
  $$ScansTableTableManager(_$AppDatabase db, $ScansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> rawName = const Value.absent(),
                Value<String> rawSetCollector = const Value.absent(),
                Value<String?> matchedScryfallId = const Value.absent(),
                Value<String?> matchedName = const Value.absent(),
                Value<String?> matchedSet = const Value.absent(),
                Value<String?> matchedCollectorNumber = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int> foilGuess = const Value.absent(),
                Value<String?> cropImagePath = const Value.absent(),
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ScansCompanion(
                id: id,
                capturedAt: capturedAt,
                rawName: rawName,
                rawSetCollector: rawSetCollector,
                matchedScryfallId: matchedScryfallId,
                matchedName: matchedName,
                matchedSet: matchedSet,
                matchedCollectorNumber: matchedCollectorNumber,
                confidence: confidence,
                foilGuess: foilGuess,
                cropImagePath: cropImagePath,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime capturedAt,
                required String rawName,
                required String rawSetCollector,
                Value<String?> matchedScryfallId = const Value.absent(),
                Value<String?> matchedName = const Value.absent(),
                Value<String?> matchedSet = const Value.absent(),
                Value<String?> matchedCollectorNumber = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<int> foilGuess = const Value.absent(),
                Value<String?> cropImagePath = const Value.absent(),
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => ScansCompanion.insert(
                id: id,
                capturedAt: capturedAt,
                rawName: rawName,
                rawSetCollector: rawSetCollector,
                matchedScryfallId: matchedScryfallId,
                matchedName: matchedName,
                matchedSet: matchedSet,
                matchedCollectorNumber: matchedCollectorNumber,
                confidence: confidence,
                foilGuess: foilGuess,
                cropImagePath: cropImagePath,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScansTable,
      Scan,
      $$ScansTableFilterComposer,
      $$ScansTableOrderingComposer,
      $$ScansTableAnnotationComposer,
      $$ScansTableCreateCompanionBuilder,
      $$ScansTableUpdateCompanionBuilder,
      (Scan, BaseReferences<_$AppDatabase, $ScansTable, Scan>),
      Scan,
      PrefetchHooks Function()
    >;
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
      Value<DateTime?> priceUpdatedAt,
      Value<String?> notes,
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
      Value<DateTime?> priceUpdatedAt,
      Value<String?> notes,
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

  ColumnFilters<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  ColumnOrderings<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  GeneratedColumn<DateTime> get priceUpdatedAt => $composableBuilder(
    column: $table.priceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
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
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
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
                priceUpdatedAt: priceUpdatedAt,
                notes: notes,
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
                Value<DateTime?> priceUpdatedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
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
                priceUpdatedAt: priceUpdatedAt,
                notes: notes,
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
  $$ScansTableTableManager get scans =>
      $$ScansTableTableManager(_db, _db.scans);
  $$CollectionTableTableManager get collection =>
      $$CollectionTableTableManager(_db, _db.collection);
}
