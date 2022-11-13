import DefaultCodable
import XCTest

final class DefaultTests: XCTestCase {
    private enum ThingType: String, Codable, CaseIterable {
        case foo, bar, baz
    }

    private struct Thing: Codable, Hashable {
        var name: String

        @Default<Empty> var description: String
        @Default<EmptyDictionary> var entities: [String: String]
        @Default<True> var isFoo: Bool
        @Default<FirstCase> var type: ThingType
        @Default<Zero> var floatingPoint: Double
        @Default<Nil> var favoriteFood: String?

        init(
            name: String,
            description: String? = nil,
            entities: [String: String]? = nil,
            isFoo: Bool? = nil,
            type: ThingType? = nil,
            floatingPoint: Double? = nil
        ) {
            self.name = name
            self._description = .init(optionalValue: description)
            self._entities = .init(optionalValue: entities)
            self._isFoo = .init(optionalValue: isFoo)
            self._type = .init(optionalValue: type)
            self._floatingPoint =  .init(optionalValue: floatingPoint)
        }
    }

    func testValueDecodesToActualValue() throws {
        // given
        let json = """
        {
          "name": "Any name",
          "description": "Any description",
          "entities": {
            "foo": "bar"
          },
          "isFoo": false,
          "type": "baz",
          "floatingPoint": 12.34
        }
        """.data(using: .utf8)!

        // when
        let result = try JSONDecoder().decode(Thing.self, from: json)

        // then
        XCTAssertEqual("Any description", result.description)
        XCTAssertEqual(["foo": "bar"], result.entities)
        XCTAssertFalse(result.isFoo)
        XCTAssertEqual(ThingType.baz, result.type)
        XCTAssertEqual(result.floatingPoint, 12.34)
    }

    func testNullDecodesToDefaultValue() throws {
        // given
        let json = """
        {
          "name": "Any name",
          "favoriteFood": null
        }
        """.data(using: .utf8)!

        // when
        let result = try JSONDecoder().decode(Thing.self, from: json)

        // then
        XCTAssertEqual("", result.description)
        XCTAssertEqual([:], result.entities)
        XCTAssertTrue(result.isFoo)
        XCTAssertEqual(ThingType.foo, result.type)
        XCTAssertEqual(result.floatingPoint, 0)
    }

    func testNotPresentValueDecodesToDefaultValue() throws {
        // given
        let json = """
        {
          "name": "Any name"
        }
        """.data(using: .utf8)!

        // when
        let result = try JSONDecoder().decode(Thing.self, from: json)

        // then
        XCTAssertEqual("", result.description)
        XCTAssertEqual([:], result.entities)
        XCTAssertTrue(result.isFoo)
        XCTAssertEqual(ThingType.foo, result.type)
        XCTAssertEqual(result.floatingPoint, 0)
    }

    func testTypeMismatchThrows() {
        // given
        let json = """
        {
          "name": "Any name",
          "description": ["nope"],
          "isFoo": 5500,
          "type": [1, 2, 3],
          "floatingPoint": "point"
        }
        """.data(using: .utf8)!

        // then
        XCTAssertThrowsError(try JSONDecoder().decode(Thing.self, from: json))
    }

    func testValueEncodesToActualValue() throws {
        // given
        let thing = Thing(
            name: "Any name",
            description: "Any description",
            entities: ["foo": "bar"],
            isFoo: false,
            type: .baz,
            floatingPoint: 12.34
        )
        let expected = """
        {
          "description" : "Any description",
          "entities" : {
            "foo" : "bar"
          },
          "floatingPoint" : 12.34,
          "isFoo" : false,
          "name" : "Any name",
          "type" : "baz"
        }
        """.data(using: .utf8)!
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        // when
        let result = try encoder.encode(thing)

        // then
        XCTAssertEqual(expected, result)
    }

    func testDefaultValueEncodesToNothing() throws {
        // given
        let thing = Thing(name: "Any name")
        let expected = """
        {
          "name" : "Any name"
        }
        """.data(using: .utf8)!
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        // when
        let result = try encoder.encode(thing)

        // then
        XCTAssertEqual(expected, result)
    }
    
    func testDecodingNullForNonOptionalFieldFails() {
        struct DeskConfiguration: Codable {
            @Default<One> var numberOfMonitors: Int
        }

        let json = #"{"numberOfMonitors": null}"#.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(DeskConfiguration.self, from: json))
    }
    
    func testAssignment() {
        struct DeskConfiguration: Codable {
            @Default<One> var numberOfMonitors: Int
        }
        
        var configuration = DeskConfiguration()
        XCTAssertEqual(configuration.numberOfMonitors, 1)
        
        configuration.numberOfMonitors = 2
        XCTAssertEqual(configuration.numberOfMonitors, 2)

        configuration.$numberOfMonitors = nil
        XCTAssertEqual(configuration.numberOfMonitors, 1)
    }
}

final class OptionalWithDefaultTests: XCTestCase {
    let jsonDecoder = JSONDecoder()
    var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
    
    struct FavoriteThings: Codable {
        @Default<Nil> var favoriteBook: String?
        @Default<Nil> var favoriteNumber: Int?
    }
    
    func testUnspecifiedFieldsDecodeToDefault() throws {
        let json = "{}".data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: json)

        XCTAssertEqual(favorites.favoriteBook, nil)
        XCTAssertEqual(favorites.favoriteNumber, nil)
    }
    
    func testNullFieldsDecodeToNil() throws {
        let json = """
        {
            "favoriteBook": null,
            "favoriteNumber": null
        }
        """.data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: json)

        XCTAssertEqual(favorites.favoriteBook, nil)
        XCTAssertEqual(favorites.favoriteNumber, nil)
    }
    
    func testDecodesNonNullValues() throws {
        let json = """
        {
            "favoriteBook": "The Hitchhiker's Guide to the Galaxy",
            "favoriteNumber": 42
        }
        """.data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: json)

        XCTAssertEqual(favorites.favoriteBook, "The Hitchhiker's Guide to the Galaxy")
        XCTAssertEqual(favorites.favoriteNumber, 42)
    }
    
    func testRoundTripWithUnspecifiedFields() throws {
        let expected = "{}".data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: expected)
        let json = try jsonEncoder.encode(favorites)
        XCTAssertEqual(expected, json)
    }
    
    func testRoundTripWithExplicitlyNullFields() throws {
        let expected = #"{"favoriteBook":null,"favoriteNumber":null}"#.data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: expected)
        let json = try jsonEncoder.encode(favorites)
        XCTAssertEqual(expected, json)
    }
    
    func testRoundTripWithNonNullFields() throws {
        let expected = #"{"favoriteBook":"The Hitchhiker's Guide to the Galaxy","favoriteNumber":42}"#
            .data(using: .utf8)!
        let favorites = try jsonDecoder.decode(FavoriteThings.self, from: expected)
        let json = try jsonEncoder.encode(favorites)
        XCTAssertEqual(expected, json)
    }
}
