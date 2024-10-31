// The Swift Programming Language
// https://docs.swift.org/swift-book

import FunctionCalling
import AnthropicSwiftSDK

extension ToolContainer {
    /// Converted tools for [AnthropicSwiftSDK](https://github.com/fumito-ito/AnthropicSwiftSDK)
    public var anthropicSwiftTools: [AnthropicSwiftSDK.Tool]? {
        guard let allTools else {
            return nil
        }
        
        return allTools.map { $0.toAnthropicSwiftTool }
    }
}

extension FunctionCalling.Tool {
    var toAnthropicSwiftTool: AnthropicSwiftSDK.Tool {
        AnthropicSwiftSDK
            .Tool
            .function(
                .init(
                    name: name,
                    description: description,
                    inputSchema: inputSchema.toAnthropicSwiftInputSchema
                )
            )
    }
}

extension FunctionCalling.InputSchema {
    var toAnthropicSwiftInputSchema: AnthropicSwiftSDK.InputSchema {
        AnthropicSwiftSDK.InputSchema(
            type: type.toAnthropicSwiftSchemaType,
            format: format,
            description: description ?? "",
            nullable: nullable,
            enumValues: enumValues,
            items: items?.toAnthropicSwiftInputSchema,
            properties: properties?.mapValues { $0.toAnthropicSwiftInputSchema },
            requiredProperties: requiredProperties
        )
    }
}

extension FunctionCalling.InputSchema.DataType {
    var toAnthropicSwiftSchemaType: AnthropicSwiftSDK.InputSchema.SchemaType {
        switch self {
        case .string:
            return .string
        case .number:
            return .number
        case .integer:
            return .integer
        case .boolean:
            return .boolean
        case .array:
            return .arrray
        case .object:
            return .object
        }
    }
}
