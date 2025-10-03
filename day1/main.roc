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
            year: 2023,
            day: 1,
            title: "Trebuchet?!",
            part1,
            part2,
        }
    )

## Solve part 1
part1 : Str -> Result Str _
part1 = |s|
    s 
    |> Str.split_on("\n")
    |> List.map(extract_digits)
    |> List.keep_oks(compute_calibration)
    |> List.sum
    |> Num.to_str
    |> Ok

extract_digits : Str -> List U64
extract_digits = |str|
    str
    |> Str.to_utf8
    |> List.keep_if(|c| c >= '0' and c <= '9')
    |> List.map(|c| Num.to_u64(c - '0'))

compute_calibration : List U64 -> Result U64 _
compute_calibration = |digits|
    List.first(digits)? * 10 + List.last(digits)? |> Ok

## Solve part 2
part2 : Str -> Result Str _
part2 = |s| 
    s 
    |> Str.split_on("\n")
    |> List.map(extract_text_digits)
    |> List.keep_oks(compute_calibration)
    |> List.sum
    |> Num.to_str
    |> Ok

extract_text_digits : Str -> List U64
extract_text_digits = |line|
    bytes = line |> Str.to_utf8
    List.range({ start: At(0), end: Length(List.len(bytes)) })
    |> List.walk([], |ds, i|
        when List.drop_first(bytes, i) is
            ['o', 'n', 'e', ..] -> List.append(ds, 1)
            ['t', 'w', 'o', ..] -> List.append(ds, 2)
            ['t', 'h', 'r', 'e', 'e', ..] -> List.append(ds, 3)
            ['f', 'o', 'u', 'r', ..] -> List.append(ds, 4)
            ['f', 'i', 'v', 'e', ..] -> List.append(ds, 5)
            ['s', 'i', 'x', ..] -> List.append(ds, 6)
            ['s', 'e', 'v', 'e', 'n', ..] -> List.append(ds, 7)
            ['e', 'i', 'g', 'h', 't', ..] -> List.append(ds, 8)
            ['n', 'i', 'n', 'e', ..] -> List.append(ds, 9)
            ['z', 'e', 'r', 'o', ..] -> List.append(ds, 0)
            [d, ..] if d >= '0' and d <= '9' -> List.append(ds, Num.to_u64(d - '0'))
            _ -> ds
    )