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
            day: 3,
            title: "Gear Ratios",
            part1,
            part2,
        },
    )

## Solve part 1
part1 : Str -> Result Str _
part1 = |s|
    lines = s |> Str.to_utf8 |> List.split_on('\n')

    schematic = parse_schematic(lines)

    extract_part_numbers(schematic, lines)
    |> List.sum
    |> Num.to_str
    |> Ok

## Parse the input lines into a list of numbers with their positions
parse_schematic : List (List U8) -> List { number : U64, row : U64, start : U64, end : U64 }
parse_schematic = |lines|
    List.walk_with_index(
        lines,
        [],
        |numbers, line, r|
            (new_numbers, last) =
                line
                |> List.walk_with_index(
                    ([], NotNumber),
                    |(row_numbers, state), c, i|
                        if c >= '0' and c <= '9' then
                            when state is
                                NotNumber -> (row_numbers, Number({ chars: [c], row: r, start: i, end: i }))
                                Number({ chars: cs, row, start, end: _ }) -> (row_numbers, Number({ chars: List.append(cs, c), row, start, end: i }))
                        else
                            when state is
                                NotNumber -> (row_numbers, NotNumber)
                                Number(part) -> (List.append(row_numbers, part), NotNumber),
                )
            List.join(
                [
                    numbers,
                    new_numbers,
                    when last is
                        Number(part) -> [part]
                        NotNumber -> [],
                ],
            ),
    )
    |> List.map(
        |{ chars, row, start, end }|
            number = chars |> Str.from_utf8_lossy |> Str.to_u64 |> Result.with_default(0)
            { number, row, start, end },
    )

## Extract part numbers that have adjacent non-numeric symbols
extract_part_numbers : List { number : U64, row : U64, start : U64, end : U64 }, List (List U8) -> List U64
extract_part_numbers = |schematic, lines|
    List.walk(
        schematic,
        [],
        |parts, number|
            adj_symbols = get_adjacent(number, lines) |> List.keep_if(|c| c != '.' and !(c >= '0' and c <= '9'))
            if !List.is_empty(adj_symbols) then
                List.append(parts, number.number)
            else
                parts,
    )

## Get all symbols adjacent to a number (horizontally, vertically, diagonally)
get_adjacent : { number : U64, row : U64, start : U64, end : U64 }, List (List U8) -> List U8
get_adjacent = |number, lines|
    len = if number.start > 0 then number.end - number.start + 3 else number.end - number.start + 2
    above =
        if number.row > 0 then
            when List.get(lines, number.row - 1) is
                Ok(line_above) ->
                    List.sublist(line_above, { start: Num.sub_saturated(number.start, 1), len })

                _ -> []
        else
            []
    (left, right) =
        when List.get(lines, number.row) is
            Ok(line) ->
                l = if number.start > 0 then List.sublist(line, { start: number.start - 1, len: 1 }) else []
                r = List.sublist(line, { start: number.end + 1, len: 1 })
                (l, r)

            _ -> ([], [])

    below =
        when List.get(lines, number.row + 1) is
            Ok(line_below) ->
                List.sublist(line_below, { start: Num.sub_saturated(number.start, 1), len })

            _ -> []

    List.join([above, left, right, below])

## Solve part 2
part2 : Str -> Result Str _
part2 = |s|
    lines = s |> Str.to_utf8 |> List.split_on('\n')

    schematic =
        parse_schematic(lines)
        |> List.walk(
            Dict.empty({}),
            |sch, n|
                when Dict.get(sch, n.row) is
                    Ok(row) -> Dict.insert(sch, n.row, List.append(row, n))
                    _ -> Dict.insert(sch, n.row, [n]),
        )

    find_and_sum_ratios(schematic, lines)
    |> Num.to_str
    |> Ok

## Find all gears (exactly 2 numbers adjacent to a '*') and their ratios (product of the two numbers) and sum the ratios
find_and_sum_ratios : Dict U64 (List { number : U64, row : U64, start : U64, end : U64 }), List (List U8) -> U64
find_and_sum_ratios = |schematic, lines|
    List.walk_with_index(
        lines,
        0,
        |outter_sum, line, r|
            List.walk_with_index(
                line,
                outter_sum,
                |sum, c, i|
                    if c == '*' then
                        adj = find_adjacent_numbers(r, i, schematic)
                        when adj is
                            [g1, g2] -> sum + (g1 * g2)
                            _ -> sum
                    else
                        sum,
            ),
    )

## Find all numbers adjacent to a given position
find_adjacent_numbers : U64, U64, Dict U64 (List { number : U64, row : U64, start : U64, end : U64 }) -> List U64
find_adjacent_numbers = |row, col, schematic|
    row_above =
        if row > 0 then
            Dict.get(schematic, row - 1) |> Result.with_default([])
        else
            []
    row_of = Dict.get(schematic, row) |> Result.with_default([])
    row_below = Dict.get(schematic, row + 1) |> Result.with_default([])

    List.join([row_above, row_of, row_below])
    |> List.walk(
        [],
        |adj, n|
            if number_is_adjacent(row, col, n) then
                adj |> List.append(n.number)
            else
                adj,
    )

## Check if a number is adjacent to a given position
number_is_adjacent : U64, U64, { row : U64, start : U64, end : U64 }a -> Bool
number_is_adjacent = |row, col, number|
    if (row > number.row and Num.sub_saturated(row, 1) == number.row) or (row + 1 == number.row) then
        if number.start > 0 then
            col >= number.start - 1 and col <= number.end + 1
        else
            col >= number.start and col <= number.end + 1
    else if row == number.row then
        if col > 0 then
            (col - 1 == number.end) or (col + 1 == number.start)
        else
            col + 1 == number.start
    else
        Bool.false

