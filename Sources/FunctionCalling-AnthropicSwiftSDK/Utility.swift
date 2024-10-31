//
//  Utility.swift
//  FunctionCalling-AnthropicSwiftSDK
//
//  Created by 伊藤史 on 2024/10/31.
//

import AnthropicSwiftSDK
import FunctionCalling

extension ToolContainer {
    /// Return the result of tool execution back to the model as a user message
    ///
    /// - Parameters:
    ///   - toolUseResponse: Message response from API to execute tools with arguments.
    ///   - messages: An array of Message objects representing the input prompt for message generation.
    ///   - model: The model to be used for generating the message. Default is `.claude_3_Opus`.
    ///   - system: The system identifier. Default is `nil`.
    ///   - maxTokens: The maximum number of tokens in the generated message.
    ///   - metaData: Additional metadata for the request. Default is `nil`.
    ///   - stopSequence: An array of strings representing sequences where the message generation should stop.
    ///   - temperature: The temperature parameter controls the randomness of the generated text. Default is `nil`.
    ///   - topP: The nucleus sampling parameter. Default is `nil`.
    ///   - topK: The top-k sampling parameter. Default is `nil`.
    ///   - toolContainer: The tool provider for `tool_use`. Default is `nil`
    ///   - toolChoice: The parameter for tool choice. Default is `.auto`
    ///   - anthropicHeaderProvider: The provider for the anthropic header NOT required for API authentication.
    ///   - authenticationHeaderProvider: The provider for the authentication header required for API authentication.
    /// - Returns: A `MessagesResponse` object representing the response from the Anthropic API.
    /// - Throws: An error if the request fails or if there's an issue decoding the response.
    func sendToolResultIfNeeded(
        _ anthropic: Anthropic,
        forResponse response: MessagesResponse,
        priviousMessages messages: [Message],
        model: Model = .claude_3_Opus,
        system: [SystemPrompt] = [],
        maxTokens: Int,
        metaData: MetaData? = nil,
        stopSequence: [String]? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        tools: [AnthropicSwiftSDK.Tool]? = nil,
        toolChoice: ToolChoice = .auto,
        anthropicHeaderProvider: AnthropicHeaderProvider,
        authenticationHeaderProvider: AuthenticationHeaderProvider
    ) async throws -> MessagesResponse {
        guard case .toolUse = response.stopReason else {
            return response
        }

        // If a `tool_use` response is returned with no `ToolContainer` specified, `tool_use_result` cannot be returned because any tool does not exist.
        guard let tools, tools.isEmpty == false else {
            throw ClientError.anyToolsAreDefined
        }

        guard case .toolUse(let toolUseContent) = response.content.first(where: { $0.contentType == .toolUse }) else {
            throw ClientError.cannotFindToolUseContentFromResponse(response)
        }

        let toolResult = await self.execute(methodName: toolUseContent.name, parameters: toolUseContent.input)
        let toolResultRequest = messages + [
            .init(role: .assistant, content: [.toolUse(toolUseContent)]),
            .init(role: .user, content: [
                .toolResult(
                    .init(
                        toolUseId: toolUseContent.id,
                        content: [
                            .text(toolResult)
                        ],
                        isError: nil
                    )
                )
            ]
            )
        ]

        return try await anthropic.messages.createMessage(
            toolResultRequest,
            model: model,
            system: system,
            maxTokens: maxTokens,
            metaData: metaData,
            stopSequence: stopSequence,
            temperature: temperature,
            topP: topP,
            topK: topK,
            tools: tools,
            toolChoice: toolChoice,
            anthropicHeaderProvider: anthropicHeaderProvider,
            authenticationHeaderProvider: authenticationHeaderProvider
        )
    }

    /// Receive response from Claude in Stream format.
    ///
    /// If there is a response related to `tool_use`, the information is compiled and streamed.
    ///
    /// - Parameters:
    ///   - stream: response stream from Claude Stream API
    ///   - messages: An array of Message objects representing the input prompt for message generation.
    ///   - model: The model to be used for generating the message. Default is `.claude_3_Opus`.
    ///   - system: The system identifier. Default is `nil`.
    ///   - maxTokens: The maximum number of tokens in the generated message.
    ///   - metaData: Additional metadata for the request. Default is `nil`.
    ///   - stopSequence: An array of strings representing sequences where the message generation should stop.
    ///   - temperature: The temperature parameter controls the randomness of the generated text. Default is `nil`.
    ///   - topP: The nucleus sampling parameter. Default is `nil`.
    ///   - topK: The top-k sampling parameter. Default is `nil`.
    ///   - toolContainer: The tool provider for `tool_use`. Default is `nil`
    ///   - toolChoice: The parameter for tool choice. Default is `.auto`
    ///   - anthropicHeaderProvider: The provider for the anthropic header NOT required for API authentication.
    ///   - authenticationHeaderProvider: The provider for the authentication header required for API authentication.
    /// - Returns: Claude Stream API response stream. If `stream` returns `tool_use` content, this method returns re-request new stream.
    func streamToolResultIfNeeded(
        _ anthropic: Anthropic,
        forStream stream: AsyncThrowingStream<StreamingResponse, Error>,
        priviousMessages: [Message],
        model: Model,
        system: [SystemPrompt],
        maxTokens: Int,
        metaData: MetaData?,
        stopSequence: [String]?,
        temperature: Double?,
        topP: Double?,
        topK: Int?,
        tools: [AnthropicSwiftSDK.Tool]? = nil,
        toolChoice: ToolChoice,
        anthropicHeaderProvider: AnthropicHeaderProvider,
        authenticationHeaderProvider: AuthenticationHeaderProvider
    ) async throws -> AsyncThrowingStream<StreamingResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await response in stream {
                        if
                            let deltaResponse = response as? StreamingMessageDeltaResponse,
                            let toolUseContent = deltaResponse.toolUseContent,
                            let toolResultContent = await deltaResponse.getToolResultContent(from: self),
                            response.isToolUse {
                            let streamWithToolResult = try await anthropic.messages.streamMessage(
                                priviousMessages + [
                                    .init(role: .assistant, content: [.toolUse(toolUseContent)]),
                                    .init(role: .user, content: [toolResultContent])
                                ],
                                model: model,
                                system: system,
                                maxTokens: maxTokens,
                                metaData: metaData,
                                stopSequence: stopSequence,
                                temperature: temperature,
                                topP: topP,
                                topK: topK,
                                tools: tools,
                                toolChoice: toolChoice,
                                anthropicHeaderProvider: anthropicHeaderProvider,
                                authenticationHeaderProvider: authenticationHeaderProvider
                            )

                            for try await responseWithToolResult in streamWithToolResult {
                                continuation.yield(responseWithToolResult)
                            }
                        } else {
                            continuation.yield(response)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

extension StreamingMessageDeltaResponse {
    /// If this response contains the `tool_use` property, the result of the `Tool` call is obtained using the `ToolContainer` given in the argument.
    /// - Parameter toolContainer: Takes the `tool_use` in the response and returns the result.
    /// - Returns: The result of tool use
    func getToolResultContent(from toolContainer: ToolContainer) async -> Content? {
        guard let toolUseContent else {
            return nil
        }

        let result = await toolContainer.execute(methodName: toolUseContent.name, parameters: toolUseContent.input)

        return .toolResult(
            .init(
                toolUseId: toolUseContent.id,
                content: [
                    .text(result)
                ],
                isError: false
            )
        )
    }
}
