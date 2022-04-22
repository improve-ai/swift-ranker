import ImproveAI

extension DecisionModel {
    public static subscript(modelName: String) -> DecisionModel {
        return DecisionModel.instances[modelName]
    }
}
