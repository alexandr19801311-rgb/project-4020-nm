param (
    [string]$RowNumber
)

# Переходим в папку с проектом
Set-Location "C:/pechnik_projects/project-4020-nm"

# Добавляем файлы в индекс Git
git add "Row_$RowNumber.png"
git add "Row_$RowNumber.json"

# Фиксируем изменения
git commit -m "BIM Снепшот: Ряд $RowNumber отправлен на валидацию"

# Пушим в твою ветку
git push origin main

Write-Host "🚀 Ряд $RowNumber успешно улетел в облако GitHub!" -ForegroundColor Green
