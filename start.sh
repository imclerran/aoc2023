#!/usr/bin/env bash

# Check if exactly 3 arguments are provided
if [ $# -ne 3 ]; then
    echo "Usage: $0 <year> <day> <title>"
    echo "Example: $0 2023 1 'Trebuchet?!'"
    exit 1
fi

# Assign arguments to variables
year=$1
day=$2
title=$3

mkdir -p "day$day"
touch "day$day/input.txt"
touch "day$day/sample.txt"

if [ -f "day$day/main.roc" ]; then
    echo "File main.roc already exists in day$day/"
else
    cat > "day$day/main.roc" <<EOL
app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
    aoc: "../../aoc-template/package/main.roc",
}

import cli.Utc
import cli.Stdout
import cli.File

import aoc.AoC {
    time!: |{}| Utc.now!({}) |> Utc.to_millis_since_epoch,
    stdout!: Stdout.write!,
    stdin!: |{}| File.read_bytes!("input.txt"),
}

main! = |_args|
    AoC.solve!(
        {
            year: $year,
            day: $day,
            title: "$title",
            part1,
            part2,
        }
    )

## Solve part 1
part1 : Str -> Result Str _
part1 = |_s| Err(Todo("Part 1 not yet implemented..."))

## Solve part 2
part2 : Str -> Result Str _
part2 = |_s| Err(Todo("Part 2 not yet implemented..."))
EOL

    echo "Created main.roc for $year Day $day: '$title' in day$day/"
fi