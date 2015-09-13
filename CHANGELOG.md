#### 2.0.1
- Add support for enums (enum values are currently encoded as integers)

#### 2.0.0
- **Breaking change**: readonly properties (final fields and getters without
  a corresponding setter) are no longer encoded. Only public read/write
  properties are encoded.
- Add indentation support during encoding through `encode`, `JsonxEncoder`,
  or `JsonxCodec`

#### 1.2.7
- Fix a small formatting error in README.md

#### 1.2.6
- Update the documentation for decoding to generics

#### 1.2.5
- Add [propertyNameDecoder] and [propertyNameEncoder]

#### 1.2.4
- Add @jsonIgnore, @jsonObject, and @jsonProperty annotations

#### 1.2.3
- Fix a typo in [_getPublicGetters]

#### 1.2.2
- Add a work-around to bug [#15942](https://code.google.com/p/dart/issues/detail?id=15942)

#### 1.2.1
- Chang [_jsonToObject] to instantiate [List] and [Map] using
  [ClassMirror.newInstance]
- Add [TypeHelper] to retrieve the runtime type of a generic type

#### 1.2.0
- Add [jsonToObjects] and [objectToJsons]
   
#### 1.1.1
- Add JsonxCodec, JsonxDecoder, and JsonxEncoder
- Add TypeMirror caching to improve the performance of `decode`

#### 1.0.9
- Change fixed length lists into growable lists in decoded objects

#### 1.0.8
- Add support for encoding/decoding memmbers of superclasses (which
  include mixins also)

#### 1.0.[1-7]
- Update dartdoc and README

#### 1.0.0
- Initial version