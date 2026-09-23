//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:trade_pilot_api_client/src/model/topup_package_option.dart';

part 'topup_config.g.dart';

/// TopupConfig
///
/// Properties:
/// * [packages] - Fixed packages accepted by POST /topups.
/// * [qrisImageUrl]
@BuiltValue()
abstract class TopupConfig implements Built<TopupConfig, TopupConfigBuilder> {
  @BuiltValueField(wireName: r'packages')
  BuiltList<TopupPackageOption> get packages;

  @BuiltValueField(wireName: r'qrisImageUrl')
  String get qrisImageUrl;

  TopupConfig._();

  factory TopupConfig([void updates(TopupConfigBuilder b)]) = _$TopupConfig;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TopupConfigBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TopupConfig> get serializer => _$TopupConfigSerializer();
}

class _$TopupConfigSerializer implements PrimitiveSerializer<TopupConfig> {
  @override
  final Iterable<Type> types = const [TopupConfig, _$TopupConfig];

  @override
  final String wireName = r'TopupConfig';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TopupConfig object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'packages';
    yield serializers.serialize(
      object.packages,
      specifiedType: const FullType(BuiltList, [FullType(TopupPackageOption)]),
    );
    yield r'qrisImageUrl';
    yield serializers.serialize(
      object.qrisImageUrl,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TopupConfig object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TopupConfigBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'packages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(TopupPackageOption),
            ]),
          ) as BuiltList<TopupPackageOption>;
          result.packages.replace(valueDes);
          break;
        case r'qrisImageUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.qrisImageUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TopupConfig deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TopupConfigBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}
