import ImproveAI

extension DecisionModel {
    public static subscript(modelName: String) -> DecisionModel {
        return DecisionModel.instances[modelName]
    }
    
    public func which(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return which(args.count, va_list)
        }
    }
    
    public func first(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return first(args.count, va_list)
        }
    }
    
    public func random(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return random(args.count, va_list)
        }
    }
}

extension DecisionContext {
    public func which(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return which(args.count, va_list)
        }
    }
    
    public func first(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return first(args.count, va_list)
        }
    }
    
    public func random(_ args: CVarArg...) ->Any {
        withVaList(args) { va_list in
            return random(args.count, va_list)
        }
    }
}
