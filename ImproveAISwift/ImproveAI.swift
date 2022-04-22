import ImproveAI

extension DecisionModel {
    public static subscript(modelName: String) -> DecisionModel {
        return DecisionModel.instances[modelName]
    }
    
    public func chooseFrom<T : Codable>(variants: [T]) -> Decision {
        let encoder = JSONEncoder()
        let encodedVariants = variants.map ({ (variant) -> Dictionary<String, Any> in
            let data = try? encoder.encode(variant)
            return try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! Dictionary<String, Any>
        })
        return chooseFrom(encodedVariants)
    }
}

extension Decision {
    public func get<T: Codable>() -> T {
        let decoder = JSONDecoder.init()
        let chosenVariant = get()
        let data = try? JSONSerialization.data(withJSONObject: chosenVariant, options: .prettyPrinted)
        return try! decoder.decode(T.self, from: data!)
    }
}
