param([Parameter(Mandatory=$true)][string]$Documento)
# Exportar el Word a PDF y actualizar los números de página. Requiere Microsoft Word.
$taskPath = (Resolve-Path -LiteralPath $Documento).Path
$taskPdf = [System.IO.Path]::ChangeExtension($taskPath, '.pdf')
$taskWord = New-Object -ComObject Word.Application
$taskWord.Visible = $false
$taskWord.DisplayAlerts = 0
$taskDoc = $null
try {
  $taskDoc = $taskWord.Documents.Open($taskPath, $false, $false)
  $taskDoc.Repaginate()
  $taskDoc.Fields.Update() | Out-Null
  foreach ($taskSection in $taskDoc.Sections) {
    foreach ($taskFooter in $taskSection.Footers) { $taskFooter.Range.Fields.Update() | Out-Null }
  }
  $taskDoc.Save()
  $taskPages = $taskDoc.ComputeStatistics(2)
  $taskDoc.ExportAsFixedFormat($taskPdf, 17)
  [pscustomobject]@{paginas=$taskPages; docx=$taskPath; pdf=$taskPdf} | ConvertTo-Json
} finally {
  if ($null -ne $taskDoc) { $taskDoc.Close($false) }
  if ($taskWord.Documents.Count -eq 0) { $taskWord.Quit() }
}
