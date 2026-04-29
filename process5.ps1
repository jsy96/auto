# AI CLI Platform - Complete with Self-Discovery
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Get-InputLine {
    param([string]$Prompt = "You")
    if ([Console]::IsInputRedirected) {
        $line = [Console]::In.ReadLine()
        if ($line -ne $null) { Write-Host "$Prompt $line" }
        return $line
    }
    return Read-Host $Prompt
}

$KEY = "c9795a87e62c4f11a37dbeeff67c3c31.RMCStcjcmj2N5g5l"
$MODEL = "glm-5.1"
$API_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"

# ============================================================================
# Dynamic Tool Loading Functions
# ============================================================================

function Get-ScriptParameters {
    param([string]$ScriptPath)

    if (-not (Test-Path $ScriptPath)) {
        return @{}
    }

    $content = Get-Content $ScriptPath -Raw -Encoding UTF8

    # Extract param block (multiline support)
    if ($content -match '(?s)param\s*\((.*?)\)') {
        $paramBlock = $matches[1]

        # Parse parameters
        $params = @{}
        $required = @()

        # Match parameter definitions like [string]$Name, [switch]$Help, etc.
        $paramRegex = '\[\s*(?:Parameter\s*\(\s*Mandatory\s*=\s*\$true\s*\)\s*)?([^\]]+)\]\s*\$([a-zA-Z_][a-zA-Z0-9_]*)'
        $simpleParamRegex = '\$\s*([a-zA-Z_][a-zA-Z0-9_]*)'

        $allMatches = [regex]::Matches($paramBlock, $paramRegex)
        $simpleMatches = [regex]::Matches($paramBlock, $simpleParamRegex)

        $paramNames = @{}
        foreach ($match in $allMatches) {
            $typeName = $match.Groups[1].Value.Trim()
            $paramName = $match.Groups[2].Value

            $paramTypes = @{
                'string' = 'string'
                'int' = 'integer'
                'integer' = 'integer'
                'bool' = 'boolean'
                'boolean' = 'boolean'
                'switch' = 'boolean'
                'double' = 'number'
                'float' = 'number'
            }

            $jsonType = if ($paramTypes.ContainsKey($typeName)) { $paramTypes[$typeName] } else { 'string' }

            if ($typeName -match 'Mandatory.*\$true') {
                $required += $paramName
            }

            $paramNames[$paramName] = $jsonType
        }

        foreach ($match in $simpleMatches) {
            $paramName = $match.Groups[1].Value
            if (-not $paramNames.ContainsKey($paramName)) {
                $paramNames[$paramName] = 'string'
            }
        }

        return @{
            parameters = $paramNames
            required = $required
        }
    }

    return @{}
}

function Build-ToolSchema {
    param(
        [string]$Name,
        [string]$Description,
        [string]$ScriptPath
    )

    $paramInfo = Get-ScriptParameters -ScriptPath $ScriptPath

    $properties = @{}
    foreach ($param in $paramInfo.parameters.Keys) {
        $properties[$param] = @{
            type = $paramInfo.parameters[$param]
            description = "Parameter: $param"
        }
    }

    return @{
        type = "function"
        function = @{
            name = $Name
            description = $Description
            parameters = @{
                type = "object"
                properties = $properties
                required = $paramInfo.required
            }
        }
    }
}

function Load-DynamicTools {
    $configPath = "storage/config.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Warning: config.json not found" -ForegroundColor Yellow
        return @()
    }

    try {
        $config = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $dynamicTools = @()

        foreach ($tool in $config.tools) {
            # Use the file path from config.json directly
            $scriptPath = $tool.file

            # Resolve relative paths
            if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                $scriptPath = Join-Path $PWD $scriptPath
            }

            if (Test-Path $scriptPath) {
                $toolSchema = Build-ToolSchema -Name $tool.name -Description $tool.description -ScriptPath $scriptPath
                $dynamicTools += $toolSchema
                Write-Host "  Loaded tool: $($tool.name) from $scriptPath" -ForegroundColor Green
            } else {
                Write-Host "  Warning: Script not found for tool: $($tool.name) at $scriptPath" -ForegroundColor Yellow
            }
        }

        return $dynamicTools
    }
    catch {
        Write-Host "Error loading config.json: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# ============================================================================
# Core Tools (built-in)
# ============================================================================

$coreTools = @(
    @{ type = "function"; function = @{
        name = "search_web"
        description = "搜索网络。Search the web using Bing. Returns search results with titles and URLs."
        parameters = @{
            type = "object"
            properties = @{
                query = @{ type = "string"; description = "搜索关键词。Search keywords." }
            }
            required = @("query")
        }
    }},
    @{ type = "function"; function = @{
        name = "fetch_url"
        description = "获取URL内容。Fetch URL content."
        parameters = @{
            type = "object"
            properties = @{
                url = @{ type = "string"; description = "要获取的URL。The URL to fetch." }
            }
            required = @("url")
        }
    }},
    @{ type = "function"; function = @{
        name = "create_script"
        description = "创建PowerShell脚本。Create PowerShell script file."
        parameters = @{
            type = "object"
            properties = @{
                filename = @{ type = "string"; description = "文件名（不需要.ps1）。Filename without .ps1 extension." }
                content = @{ type = "string"; description = "脚本内容。Script content." }
            }
            required = @("filename", "content")
        }
    }},
    @{ type = "function"; function = @{
        name = "register_tool"
        description = "注册工具到config.json。Register tool in config.json."
        parameters = @{
            type = "object"
            properties = @{
                name = @{ type = "string" }
                description = @{ type = "string" }
                file = @{ type = "string" }
            }
            required = @("name", "description", "file")
        }
    }}
)

# ============================================================================
# Load Dynamic Tools from config.json
# ============================================================================

Write-Host "Loading tools..." -ForegroundColor Cyan
$dynamicTools = Load-DynamicTools
$tools = $coreTools + $dynamicTools

Write-Host "Total tools available: $($tools.Count)" -ForegroundColor Green
Write-Host "Core tools: $($coreTools.Count)" -ForegroundColor Cyan
Write-Host "Dynamic tools: $($dynamicTools.Count)" -ForegroundColor Yellow
Write-Host ""

Write-Host "AI CLI Platform - Self-Discovery Mode" -ForegroundColor Cyan
Write-Host "Tools: Web search, URL fetch, Script creation, Tool registration" -ForegroundColor Yellow
Write-Host ""

$messages = @(
    @{
        role = "system"
        content = "你是智能CLI平台助手。你有以下可用的工具：

**天气查询工具（已配置，可直接使用）：**
- wttr: 查询天气，无需API密钥，完全免费。参数：City（城市名）
- weather_query: 使用WeatherAPI.com查询天气。参数：City, ApiKey
- openweather_map: 使用OpenWeatherMap查询天气。参数：City, ApiKey

**核心工具：**
- search_web: 搜索网络，查找API文档和资源
- fetch_url: 获取URL内容，阅读API文档
- create_script: 创建PowerShell脚本
- register_tool: 注册新工具到config.json

**工作流程：**
1. 如果用户要求查询天气，直接使用wttr工具（无需API密钥）
2. 如果用户要求配置新工具，使用search_web查找相关资源
3. 使用fetch_url获取文档内容
4. 使用create_script创建脚本
5. 使用register_tool注册到config.json

**重要：** 对于天气查询，优先使用wttr工具，因为它不需要API密钥且已经配置好！
"
    }
)

# ============================================================================
# Token Management Functions
# ============================================================================

function Get-ApproximateTokenCount {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return 0
    }

    # 粗略估算：英文 ~4 chars/token, 中文 ~1.5 chars/token
    $englishChars = ($Text -replace '[^\x00-\x7F]', '').Length
    $chineseChars = ($Text.Length - $englishChars)

    $englishTokens = [math]::Ceiling($englishChars / 4)
    $chineseTokens = [math]::Ceiling($chineseChars / 1.5)

    return $englishTokens + $chineseTokens
}

function Get-ContextTokenCount {
    $totalTokens = 0

    foreach ($msg in $messages) {
        $content = if ($msg.content) { $msg.content } else { "" }
        $totalTokens += Get-ApproximateTokenCount -Text $content

        # Count tool_calls
        if ($msg.tool_calls) {
            foreach ($tc in $msg.tool_calls) {
                $totalTokens += 20  # Base overhead per tool call
                if ($tc.function.arguments) {
                    $totalTokens += Get-ApproximateTokenCount -Text $tc.function.arguments
                }
            }
        }
    }

    return $totalTokens
}

function Show-TokenUsage {
    $used = Get-ContextTokenCount
    $maxTokens = 128000  # GLM-4 context window

    Write-Host "`n[Tokens: $used / $maxTokens (" -NoNewline
    $percentage = [math]::Round(($used / $maxTokens) * 100, 1)

    if ($percentage -lt 50) {
        Write-Host "$percentage%" -ForegroundColor Green -NoNewline
    } elseif ($percentage -lt 80) {
        Write-Host "$percentage%" -ForegroundColor Yellow -NoNewline
    } else {
        Write-Host "$percentage%" -ForegroundColor Red -NoNewline
    }

    Write-Host ")]" -NoNewline
}

# ============================================================================
# Streaming API Function
# ============================================================================

function Invoke-StreamingApi {
    param(
        [hashtable]$Body,
        [string]$ApiUrl,
        [string]$ApiKey
    )

    $Body["stream"] = $true
    $bodyJson = $Body | ConvertTo-Json -Depth 10
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyJson)

    $webRequest = [System.Net.WebRequest]::Create($ApiUrl)
    $webRequest.Method = "POST"
    $webRequest.ContentType = "application/json; charset=utf-8"
    if ($ApiKey) {
        $webRequest.Headers.Add("Authorization", "Bearer $ApiKey")
    }

    $requestStream = $webRequest.GetRequestStream()
    $requestStream.Write($bodyBytes, 0, $bodyBytes.Length)
    $requestStream.Close()

    $webResponse = $webRequest.GetResponse()
    $responseStream = $webResponse.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($responseStream, [System.Text.Encoding]::UTF8)

    $fullContent = [System.Text.StringBuilder]::new()
    $toolCallsMap = @{}
    $hasToolCalls = $false

    while (-not $reader.EndOfStream) {
        $line = $reader.ReadLine()

        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        if ($line -match '^data:\s*(.*)') {
            $dataStr = $matches[1].Trim()

            if ($dataStr -eq '[DONE]') { break }

            try {
                $chunk = $dataStr | ConvertFrom-Json
                $delta = $chunk.choices[0].delta

                if ($null -ne $delta.content -and $delta.content -ne "") {
                    Write-Host $delta.content -NoNewline -ForegroundColor White
                    [void]$fullContent.Append($delta.content)
                }

                if ($delta.tool_calls) {
                    $hasToolCalls = $true
                    foreach ($tc in $delta.tool_calls) {
                        $idx = [string]$tc.index
                        if (-not $toolCallsMap.ContainsKey($idx)) {
                            $toolCallsMap[$idx] = @{
                                id = ""
                                name = ""
                                arguments = ""
                            }
                        }
                        if ($tc.id) {
                            $toolCallsMap[$idx].id += $tc.id
                        }
                        if ($null -ne $tc.function -and $tc.function.name) {
                            $toolCallsMap[$idx].name += $tc.function.name
                        }
                        if ($null -ne $tc.function -and $tc.function.arguments) {
                            $toolCallsMap[$idx].arguments += $tc.function.arguments
                        }
                    }
                }
            }
            catch {
                # Skip unparseable chunks
            }
        }
    }

    $reader.Close()
    $responseStream.Close()

    $msg = @{
        role = "assistant"
        content = $fullContent.ToString()
    }

    if ($hasToolCalls) {
        $tcArray = [System.Collections.ArrayList]::new()
        foreach ($key in ($toolCallsMap.Keys | Sort-Object { [int]$_ })) {
            [void]$tcArray.Add(@{
                id = $toolCallsMap[$key].id
                type = "function"
                function = @{
                    name = $toolCallsMap[$key].name
                    arguments = $toolCallsMap[$key].arguments
                }
            })
        }
        $msg["tool_calls"] = $tcArray
    }

    return @{
        message = $msg
        toolCalls = if ($hasToolCalls) { $msg["tool_calls"] } else { $null }
    }
}

$tokenWarnThreshold = 0.7  # 70%
$tokenCriticalThreshold = 0.85  # 85%

while ($true) {
    $inp = Get-InputLine "You"
    if ($inp -eq ":quit") { break }
    if ($inp -eq ":clear") {
        # Clear all messages except system prompt
        $messages = @($messages[0])
        Clear-Host
        Write-Host "✓ Context cleared (system prompt preserved)" -ForegroundColor Green
        Write-Host ""
        continue
    }
    if ($inp -eq ":tokens") {
        Show-TokenUsage
        Write-Host ""
        continue
    }
    if ([string]::IsNullOrWhiteSpace($inp)) { continue }

    try {
        $messages += @{ role = "user"; content = $inp }

        Write-Host ""
        $result = Invoke-StreamingApi -Body @{
            model = $MODEL
            messages = $messages
            tools = $tools
            temperature = 0.7
        } -ApiUrl $API_URL -ApiKey $KEY

        $assistantMessage = $result.message
        $toolCalls = $result.toolCalls
        $messages += $assistantMessage

        $maxTurns = 15
        $currentTurn = 0

        while ($currentTurn -lt $maxTurns -and $toolCalls) {
            $tcIdx = 0
            foreach ($toolCall in $toolCalls) {
                $functionName = $toolCall.function.name
                $functionArgs = $toolCall.function.arguments | ConvertFrom-Json
                $toolCallId = $toolCall.id

                Write-Host ""
                Write-Host "[$currentTurn.$($tcIdx+1)] $functionName" -ForegroundColor Cyan

                $result = switch ($functionName) {
                    "search_web" {
                        $query = $functionArgs.query
                        Write-Host "  Query: $query" -ForegroundColor Yellow

                        $result = "Search results for '$query':`n`n"
                        $totalCount = 0

                        # Use Bing (works reliably without CAPTCHA)
                        try {
                            $encodedQuery = [System.Uri]::EscapeDataString($query)
                            $url = "https://www.bing.com/search?q=$encodedQuery"
                            $response = Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -UseBasicParsing -TimeoutSec 20
                            $html = $response.Content

                            # Pattern: <h2><a href="URL">Title</a>
                            $pattern = '<h2[^>]*><a[^>]*href="([^"]*)"[^>]*>([^<]+)</a>'
                            $urlMatches = [regex]::Matches($html, $pattern)

                            foreach ($match in $urlMatches) {
                                if ($totalCount -ge 10) { break }

                                $realUrl = $match.Groups[1].Value
                                $title = $match.Groups[2].Value -replace '<[^>]*>', '' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"'

                                # Skip internal Bing links
                                if ($realUrl -notmatch 'bing\.com' -and -not [string]::IsNullOrWhiteSpace($title)) {
                                    $result += "$($totalCount+1). $title`n   URL: $realUrl`n`n"
                                    $totalCount++
                                }
                            }
                        }
                        catch {
                            Write-Host "  Search failed: $($_.Exception.Message)" -ForegroundColor Yellow
                        }

                        if ($totalCount -eq 0) {
                            $result = "No results found. Try different keywords."
                        }
                        else {
                            $result += "`nNext step: Use fetch_url with one of the URLs above to read API documentation."
                        }

                        Write-Host "  Found: $totalCount results" -ForegroundColor Green
                        $result
                    }
                    "fetch_url" {
                        $url = $functionArgs.url
                        Write-Host "  URL: $url" -ForegroundColor Yellow
                        try {
                            $response = Invoke-WebRequest -Uri $url -UserAgent "Mozilla/5.0" -UseBasicParsing -TimeoutSec 30
                            $content = $response.Content
                            if ($content.Length -gt 10000) {
                                $content = $content.Substring(0, 10000) + "`n`n... (truncated, content too long)"
                            }
                            Write-Host "  Fetched: $($content.Length) chars" -ForegroundColor Green
                            $content
                        }
                        catch {
                            $err = "Error: $($_.Exception.Message)"
                            Write-Host "  $err" -ForegroundColor Red
                            $err
                        }
                    }
                    "create_script" {
                        $filename = $functionArgs.filename
                        $content = $functionArgs.content
                        if (-not $filename.EndsWith('.ps1')) { $filename += '.ps1' }
                        Write-Host "  File: $filename" -ForegroundColor Yellow
                        try {
                            if (-not (Test-Path "storage/tools")) {
                                New-Item -ItemType Directory -Path "storage/tools" -Force | Out-Null
                            }
                            $content | Out-File -FilePath "storage/tools/$filename" -Encoding UTF8
                            Write-Host "  Created" -ForegroundColor Green
                            "Created: storage/tools/$filename"
                        }
                        catch {
                            $err = "Error: $($_.Exception.Message)"
                            Write-Host "  $err" -ForegroundColor Red
                            $err
                        }
                    }
                    "register_tool" {
                        $name = $functionArgs.name
                        $description = $functionArgs.description
                        $file = $functionArgs.file
                        Write-Host "  Name: $name" -ForegroundColor Yellow
                        try {
                            if (-not (Test-Path "storage")) {
                                New-Item -ItemType Directory -Path "storage" -Force | Out-Null
                            }
                            if (Test-Path "storage/config.json") {
                                $config = Get-Content "storage/config.json" -Raw -Encoding UTF8 | ConvertFrom-Json
                            } else {
                                $config = @{ tools = @() } | ConvertTo-Json | ConvertFrom-Json
                            }
                            $toolsList = [System.Collections.ArrayList]::new()
                            foreach ($t in $config.tools) { [void]$toolsList.Add($t) }
                            [void]$toolsList.Add(@{
                                name = $name
                                description = $description
                                file = $file
                                category = "ai-discovered"
                            })
                            $config.tools = $toolsList
                            $config | ConvertTo-Json -Depth 10 | Out-File "storage/config.json" -Encoding UTF8
                            Write-Host "  Registered" -ForegroundColor Green
                            "Registered: $name"
                        }
                        catch {
                            $err = "Error: $($_.Exception.Message)"
                            Write-Host "  $err" -ForegroundColor Red
                            $err
                        }
                    }
                    default {
                        # Check if this is a dynamic tool from config.json
                        $config = Get-Content "storage/config.json" -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
                        $tool = $config.tools | Where-Object { $_.name -eq $functionName }

                        if ($tool) {
                            $scriptPath = $tool.file

                            # Resolve path if relative
                            if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
                                $scriptPath = Join-Path "storage/tools" (Split-Path $scriptPath -Leaf)
                            }

                            if (Test-Path $scriptPath) {
                                Write-Host "  Script: $scriptPath" -ForegroundColor Yellow

                                # Build arguments
                                $argList = @()
                                foreach ($arg in $functionArgs.PSObject.Properties) {
                                    $value = $arg.Value
                                    if ($value -is 'string') {
                                        $argList += "-$($arg.Name)"
                                        $argList += "`"$value`""
                                    } elseif ($value -is 'bool') {
                                        if ($value) {
                                            $argList += "-$($arg.Name)"
                                        }
                                    } else {
                                        $argList += "-$($arg.Name)"
                                        $argList += $value
                                    }
                                }

                                Write-Host "  Args: $($argList -join ' ')" -ForegroundColor Gray

                                try {
                                    # Execute script and capture output
                                    $output = powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath $argList 2>&1

                                    if ($LASTEXITCODE -eq 0) {
                                        $outputString = $output -join "`n"
                                        Write-Host "  Success" -ForegroundColor Green
                                        $outputString
                                    } else {
                                        $errorString = $output -join "`n"
                                        Write-Host "  Exit code: $LASTEXITCODE" -ForegroundColor Red
                                        "Error: $errorString"
                                    }
                                }
                                catch {
                                    $err = "Error executing script: $($_.Exception.Message)"
                                    Write-Host "  $err" -ForegroundColor Red
                                    $err
                                }
                            } else {
                                $err = "Error: Script not found at $scriptPath"
                                Write-Host "  $err" -ForegroundColor Red
                                $err
                            }
                        } else {
                            $err = "Error: Unknown tool '$functionName'"
                            Write-Host "  $err" -ForegroundColor Red
                            $err
                        }
                    }
                }

                $messages += @{
                    role = "tool"
                    tool_call_id = $toolCallId
                    content = $result
                }
                $tcIdx++
            }

            # Next API call
            Write-Host ""
            $result = Invoke-StreamingApi -Body @{
                model = $MODEL
                messages = $messages
                tools = $tools
                temperature = 0.7
            } -ApiUrl $API_URL -ApiKey $KEY

            $assistantMessage = $result.message
            $toolCalls = $result.toolCalls
            $messages += $assistantMessage
            $currentTurn++
        }

        if ($assistantMessage.content) {
            Write-Host ""

            # Check token usage after each response
            $usedTokens = Get-ContextTokenCount
            $maxTokens = 128000  # GLM-4 context window
            $usageRatio = $usedTokens / $maxTokens

            if ($usageRatio -gt $tokenCriticalThreshold) {
                Write-Host "`n⚠️  WARNING: Context is at $($usageRatio.ToString("P0")) capacity!" -ForegroundColor Red
                Write-Host "This may degrade performance. Clear conversation history? (y/n): " -NoNewline -ForegroundColor Yellow
                $clearChoice = Read-Host

                if ($clearChoice -eq 'y' -or $clearChoice -eq 'Y') {
                    # Clear all messages except system prompt
                    $messages = @($messages[0])
                    Write-Host "✓ Context cleared (system prompt preserved)" -ForegroundColor Green
                }
            }
            elseif ($usageRatio -gt $tokenWarnThreshold) {
                Write-Host "`nℹ️  Info: Context at $($usageRatio.ToString("P0")) capacity. Type ':clear' to clear if needed." -ForegroundColor Cyan
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Goodbye!"
