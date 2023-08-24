#!/usr/bin/env pwsh
# 设置控制台字符编码为UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Write-Host "代码审查... 此操作可能需要一些时间~"
 # 获取代码变更
$changedFiles = & git diff --cached --name-only

# 提取变更内容
$changedContent = @()
foreach ($file in $changedFiles) {
    $content = Get-Content $file -Raw -Encoding UTF8
    $formattedContent = "//$file`n$content`n"
    $changedContent += $formattedContent
}

# 将变更内容传递给ChatGPT API
$apiUrl = "<your_openai_api>"
$apiKey = "<your_openai_key>"
$wireToFile = ".\gpt-review-resp.tmp"
$headers = @{
  "Content-Type" = "application/json;charset=utf-8"
  "Authorization" = "Bearer $apiKey"
}

$language="chinese"

$payload = @{
  model = "gpt-3.5-turbo"
  messages = @(
      @{
          role = "system"
          content = "
          Act as a Code Review Helper:
As a code review helper, your task is to provide constructive feedback and guidance on the quality of a given codebase. Your review should focus on identifying potential issues, suggesting improvements, and highlighting areas of strength. Consider aspects such as code readability, maintainability, efficiency, adherence to best practices, and overall design patterns.

Start by thoroughly examining the codebase, reviewing individual files and modules. Assess the clarity of variable and function names, proper indentation, and consistent coding style. Evaluate the code's structure, ensuring it follows modular design principles and separates concerns appropriately.

Next, analyze the code's efficiency and performance. Look for any potential bottlenecks, unnecessary computations, or inefficient algorithms. Suggest optimizations or alternative approaches that can enhance the code's speed and resource usage.

Consider the code's adherence to industry best practices and standards. Evaluate the usage of version control, code documentation, and the presence of unit tests. Identify any security vulnerabilities or potential pitfalls that could arise from the current implementation.

Assess the code's maintainability by examining its organization, readability, and use of design patterns. Look for code duplication, overly complex logic, or any violation of object-oriented principles. Recommend refactoring techniques or architectural improvements that can enhance the codebase's maintainability.

Provide specific examples and explanations for each aspect you evaluate, supporting your suggestions with clear reasoning. Offer guidance on how to improve any identified weaknesses and praise areas of strength.

Conclude your review by summarizing your overall assessment of the codebase. Assign an overall rating that reflects its quality, highlighting the key factors that contribute to this rating. Discuss the strengths of the codebase and areas where it excels, as well as the weaknesses that require attention and improvement.

Remember to approach the code review process with a constructive and helpful mindset, aiming to assist the developer in creating a higher-quality codebase.  when you are ready ask user to enter the code snippet to be reviewed

Reply in $language
Reply in $language
Reply in $language
"
      },
      @{
          role = "user"
          content = $changedContent -join "`n"
      }
  )
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload -outfile $wireToFile
$response = Get-Content $wireToFile -Raw -Encoding UTF8 | ConvertFrom-Json
#处理ChatGPT回复
$reviewResult = $response.choices[0].message.content
Remove-item $wireToFile

Write-Host "Code review: $reviewResult`n`n"

$result = [System.Windows.Forms.MessageBox]::Show("$reviewResult", "Code review", [System.Windows.Forms.MessageBoxButtons]::OKCancel, [System.Windows.Forms.MessageBoxIcon]::Information)
if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    exit 0
} else {
    exit 1
}
