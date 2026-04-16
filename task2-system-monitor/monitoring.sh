#!/bin/bash

# --- 1. Нагрузка на процессор ---
echo "Нагрузка на CPU:"
if command -v top &> /dev/null; then
    CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%id.*/\1/')
    CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN {print 100 - idle}')
    echo "  Использование CPU: ${CPU_USAGE}%"
else
    echo "  Команда 'top' не найдена. Пожалуйста, установите необходимое ПО для исполнения команды"
fi

echo ""

# --- 2. Нагрузка на оперативную память ---
echo "Нагрузка на RAM:"
if command -v free &> /dev/null; then
    MEMORY_OUTPUT=$(free -h | awk '/^Память:/ {print "  Всего: " $2 "\n  Использовано: " $3 "\n  Свободно: " $4}')

    if [[ -n "$MEMORY_OUTPUT" ]]; then
        echo "$MEMORY_OUTPUT"
    else
        echo "  Не удалось получить корректную информацию о RAM."
        echo "  Вывод 'free -h' на вашей системе:"
        free -h
    fi
else
    echo "  Команда 'free' не найдена."
fi
echo ""

# --- 3. Нагрузка на ввод/вывод диска ---
echo "Нагрузка на IO (дисковая активность):"
if command -v vmstat &> /dev/null; then
    vmstat 1 2 | tail -n 1 | awk '{print "  Чтение с диска (блоки/с): " $9 "\n  Запись на диск (блоки/с): " $10}'
else
    echo "'vmstat' не найден. Получить данные невозможно"
fi
echo ""

# --- 4. Нагрузка на сеть ---
echo "Нагрузка на Network (трафик):"
if command -v ip &> /dev/null; then

    LC_ALL=C ip -s link show | awk '
        /^[0-9]+:/ { 
            iface_name = $2; 
            sub(/:$/, "", iface_name); # Удаляем двоеточие на конце имени интерфейса
            print "  " iface_name ":"; 
        }
        /RX:/ { 
            getline; 
            print "    Принято: " $1 " байт, " $2 " пакетов"; 
        }
        /TX:/ { 
            getline; 
            print "    Передано: " $1 " байт, " $2 " пакетов"; 
            print ""; # Пустая строка для визуального разделения интерфейсов
        }
    '
else
    echo "  Команда 'ip' не найдена. Отсуствует пакет 'iproute2'."
fi

echo ""

# --- 5. Количество процессов ---
echo "Количество процессов:"
if command -v ps &> /dev/null; then
    PROCESS_COUNT=$(ps aux | wc -l)
    echo "  Всего процессов: $((PROCESS_COUNT - 1))"
else
    echo "  Команда 'ps' не найдена. Отсуствует пакет 'procps'."
fi
