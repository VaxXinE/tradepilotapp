//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'topup_package_option.g.dart';

/// A fixed Rupiah-to-credit package offered by the backend.
@BuiltValue()
abstract class TopupPackageOption
    implements Built<TopupPackageOption, TopupPackageOptionBuilder> {
  @BuiltValueField(wireName: r'amountRupiah')
  int get amountRupiah;

  @BuiltValueField(wireName: r'credits')
  int get credits;

  TopupPackageOption._();

  factory TopupPackageOption(
      [void updates(TopupPackageOptionBuilder builder)]) = _$TopupPackageOption;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TopupPackageOptionBuilder builder) => builder;

  @BuiltValueSerializer(custom: true)
  static Serializer<TopupPackageOption> get serializer =>
      _$TopupPackageOptionSerializer();
}

class _$TopupPackageOptionSerializer
    implements PrimitiveSerializer<TopupPackageOption> {
  @override
  final Iterable<Type> types = const [
    TopupPackageOption,
    _$TopupPackageOption,
  ];

  @override
  final String wireName = r'TopupPackageOption';

  @override
  Object serialize(
    Serializers serializers,
    TopupPackageOption object, {
    FullType specifiedType = FullType.unspecified,
  }) =>
      <Object?>[
        r'amountRupiah',
        serializers.serialize(
          object.amountRupiah,
          specifiedType: const FullType(int),
        ),
        r'credits',
        serializers.serialize(object.credits,
            specifiedType: const FullType(int)),
      ];

  @override
  TopupPackageOption deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final values = (serialized as Iterable<Object?>).toList();
    final result = TopupPackageOptionBuilder();
    for (var index = 0; index < values.length; index += 2) {
      switch (values[index] as String) {
        case r'amountRupiah':
          result.amountRupiah = serializers.deserialize(
            values[index + 1],
            specifiedType: const FullType(int),
          ) as int;
          break;
        case r'credits':
          result.credits = serializers.deserialize(
            values[index + 1],
            specifiedType: const FullType(int),
          ) as int;
          break;
      }
    }
    return result.build();
  }
}
