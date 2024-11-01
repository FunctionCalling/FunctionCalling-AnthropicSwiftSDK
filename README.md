# FunctionCalling-AnthropicSwiftSDK

This library simplifies the integration of the [FunctionCalling](https://github.com/fumito-ito/FunctionCalling) macro into [AnthropicSwiftSDK](https://github.com/fumito-ito/AnthropicSwiftSDK). By using this library, you can directly generate `Tool` objects from Swift native functions, which can then be specified as FunctionCalling when invoking AnthropicSwiftSDK.

## Usage

```swift

import FunctionCalling
import FunctionCalling_AnthropicSwiftSDK
import AnthropicSwiftSDK

// MARK: Declare the container and functions for the tools to be called from FunctionCalling.

@FunctionCalling(service: .claude)
struct MyFunctionTools: ToolContainer {
    @CallableFunction
    /// Get the current stock price for a given ticker symbol
    ///
    /// - Parameter: The stock ticker symbol, e.g. AAPL for Apple Inc.
    func getStockPrice(ticker: String) async throws -> String {
        // code to return stock price of passed ticker
    }
}


let result = try await Anthropic(apiKey: "your_claude_api_key")
    .createMessage(
        [message],
        maxTokens: 1024,
        tools: MyFunctionTools().anthropicSwiftTools // <= pass tool container here
    )
```

## Installation

### Swift Package Manager

```
let package = Package(
    name: "MyPackage",
    products: [...],
    targets: [
        .target(
            "YouAppModule",
            dependencies: [
                .product(name: "FunctionCalling-AnthropicSwiftSDK", package: "FunctionCalling-AnthropicSwiftSDK")
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/FunctionCalling/FunctionCalling-AnthropicSwiftSDK", from: "0.1.0")
    ]
)
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

The MIT License
