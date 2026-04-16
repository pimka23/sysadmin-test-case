# Поиск процессов с высоким потреблением ресурсов CPU
# Из списка процессов выбираем занимающие более 50% CPU в течение 10 минут.

# Настройки
$DurationMinutes = 10     # Общая длительность наблюдения (мин.)
$IntervalSeconds = 10     # Интервал между замерами (сек.)
$CpuThreshold    = 50     # Порог загрузки CPU (%)

# Вычисление количества итераций
$MaxSamples = ($DurationMinutes * 60) / $IntervalSeconds

Clear-Host
Write-Host "Анализ потребления CPU"
Write-Host "Длительность сбора данных: $DurationMinutes минут."
Write-Host "Порог срабатывания: > $CpuThreshold% CPU.`n"

# Создаем массив для хранения данных
$allSamples = @()

# 1. Сбор данных
# Используем ручной цикл,так как Get-Counter (-SampleInterval) падает с ошибкой "InvalidResult", если за время наблюдения фоновые процессы появляются и исчезают.
for ($i = 0; $i -lt $MaxSamples; $i++) {
    
    # Выводим статус итераций
    Write-Progress -Activity "Сбор метрик производительности" -Status "Итерация $($i+1) из $MaxSamples" 

    # Делаем "снимок" загрузки CPU для всех запущенных процессов.
    # Путь к счетчику для русской версии Windows. Для англоязычной сборки надо соответственно поменять.
    # -ErrorAction SilentlyContinue игнорит ошибки исчезнувших процессов.
    $snapshot = Get-Counter -Counter "\Процесс(*)\% загруженности процессора" -ErrorAction SilentlyContinue
    
    if ($snapshot) {
        $allSamples += $snapshot.CounterSamples
    }
    
    # Ожидание перед следующим снимком
    Start-Sleep -Seconds $IntervalSeconds
}

# Убираем надпись после выпонения
Write-Progress -Activity "Сбор метрик производительности" -Completed

Write-Host "Сбор данных завершен. Анализируем результаты...`n"

# 2. Обработка и фильтрация
# Сохраняем результаты анализа в переменную
$highCpuProcesses = $allSamples | 
    Where-Object { $_.InstanceName -notmatch "(idle|_total|бездействие)" } | 
    Group-Object InstanceName | 
    ForEach-Object {
        $avgCpu = ($_.Group | Measure-Object CookedValue -Average).Average
        
        if ($avgCpu -gt $CpuThreshold) {
            [PSCustomObject]@{
                'Имя процесса' = $_.Name
                'Средний CPU (%)' = [math]::Round($avgCpu, 2)
            }
        }
    }

# 3. Вывод результатов
# Проверяем, наличие искомых процессов
if ($null -ne $highCpuProcesses -and $highCpuProcesses.Count -gt 0) {
    # Если процессы найдены, генерируем таблицу
    $highCpuProcesses | Format-Table -AutoSize
} else {
    # Если переменная пуста, выводим текст
    Write-Host "Процессов, нагружающих процессор более чем на $CpuThreshold% за заданное время, не обнаружено."
}

Write-Host "`nАнализ завершен."