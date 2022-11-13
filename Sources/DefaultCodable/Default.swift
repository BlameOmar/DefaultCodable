import Foundation

@propertyWrapper
public struct Default<Provider: DefaultValueProvider>: Codable {
    var explicitValue: Provider.Value? = nil
    
    public var wrappedValue: Provider.Value {
        get {
            explicitValue ?? Provider.default
        }
        set {
            explicitValue = newValue
        }
    }

    public var projectedValue: Provider.Value? {
        get {
            explicitValue
        }
        set {
            explicitValue = newValue
        }
    }
    
    public init() {}
    
    public init(wrappedValue: Provider.Value) {
        self.explicitValue = wrappedValue
    }
    
    public init(optionalValue value: Provider.Value?) {
        self.explicitValue = value
    }
}

extension Default: Equatable where Provider.Value: Equatable {}
extension Default: Hashable where Provider.Value: Hashable {}

public extension KeyedDecodingContainer {
    func decode<P>(_: Default<P>.Type, forKey key: Key) throws -> Default<P> {
        if !contains(key) {
            return Default()
        }
        let value = try decode(P.Value.self, forKey: key)
        return Default(wrappedValue: value)
    }
}

public extension KeyedEncodingContainer {
    mutating func encode<P>(_ value: Default<P>, forKey key: Key) throws {
        guard value.explicitValue != nil else { return }
        try encode(value.wrappedValue, forKey: key)
    }
}
