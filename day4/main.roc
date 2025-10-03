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
            day: 4,
            title: "Scratchcards",
            part1,
            part2,
        }
    )

## Implement your part1 and part2 solutions here
part1 : Str -> Result Str _
part1 = |s| Str.split_on(s, "\n") |> score_tickets_p1(0) |> Num.to_str |> Ok

score_tickets_p1 = |lines, total|
    when lines is
        [] -> total
        [line, .. as rest] ->
            score = score_ticket_p1(line)
            score_tickets_p1(rest, total + score)

score_ticket_p1 = |ticket|
    { winning, card } =
        when Str.split_on(ticket, ": ") is
            [_, scores] ->
                when Str.split_on(scores, " | ") is
                    [win_str, card_str] ->
                        {
                            winning: Str.split_on(win_str, " ") |> List.keep_oks(Str.to_u8),
                            card: Str.split_on(card_str, " ") |> List.keep_oks(Str.to_u8),
                        }

                    _ ->
                        { winning: [], card: [] }

            _ -> { winning: [], card: [] }

    List.walk(
        card,
        0,
        |score, num|
            if List.contains(winning, num) then
                if score == 0 then 1 else score * 2
            else
                score,
    )

part2 : Str -> Result Str _
part2 = |s| Str.split_on(s, "\n") |> score_tickets_p2(0, []) |> Num.to_str |> Ok

score_tickets_p2 = |lines, total, extras|
    when lines is
        [] -> total
        [line, .. as rest] ->
            score = score_ticket_p2(line)
            ex = List.get(extras, 0) |> Result.with_default 0
            new_extras = List.drop_first(extras, 1) |> update_extras(score, ex + 1)
            new_total = total + 1 + ex
            score_tickets_p2(rest, new_total, new_extras)

## extras: List of index offsets to give extra tickets (where 0 is the offset of the first ticket to gain extras)
## count: the number of tickets which should gain extras
## mult: the number of multiples of the current winning ticket, such that each each ticket should gain the number of extas
update_extras = |extras, count, mult|
    help = |ex, cnt, idx|
        if idx < cnt then
            when List.get(ex, idx) is
                Ok(n) ->
                    nn = n + mult
                    ext = List.set(ex, idx, nn)
                    help(ext, cnt, idx + 1)

                Err(OutOfBounds) ->
                    ext = List.append(ex, mult)
                    help(ext, cnt, idx + 1)
        else
            ex
    help(extras, count, 0)

score_ticket_p2 = |ticket|
    { winning, card } =
        when Str.split_on(ticket, ": ") is
            [_, scores] ->
                when Str.split_on(scores, " | ") is
                    [win_str, card_str] ->
                        {
                            winning: Str.split_on(win_str, " ") |> List.keep_oks(Str.to_u8),
                            card: Str.split_on(card_str, " ") |> List.keep_oks(Str.to_u8),
                        }

                    _ ->
                        { winning: [], card: [] }

            _ -> { winning: [], card: [] }

    List.count_if(card, |n| List.contains(winning, n))
