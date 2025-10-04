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
            day: 2,
            title: "Cube Conundrum",
            part1,
            part2,
        },
    )

initial_bag = { red: 12, green: 13, blue: 14 }

## Solve part 1
part1 : Str -> Result Str _
part1 = |s|
    s
    |> Str.trim
    |> Str.split_on("\n")
    |> List.map_try(parse_game)?
    |> List.keep_if(|game| game_possible(game, initial_bag))
    |> List.map(.id)
    |> List.sum
    |> Num.to_str
    |> Ok

CubeSet : { red : U64, green : U64, blue : U64 }
Game : { id : U64, rounds : List CubeSet }

parse_game : Str -> Result Game _
parse_game = |s|
    { before: id_str, after: round_str } =
        Str.drop_prefix(s, "Game ")
        |> Str.split_first(":")
        |> Result.map_err(|_| InvalidGame(s))?
    id = Str.to_u64(id_str) ? |_| InvalidGameId(id_str)
    rounds =
        round_str
        |> Str.split_on(";")
        |> List.map_try(parse_round)?
    Ok({ id, rounds })

parse_round : Str -> Result CubeSet _
parse_round = |s|
    s
    |> Str.trim
    |> Str.split_on(",")
    |> List.map_try(parse_color)
    |> Result.map_err(InvalidRound)?
    |> List.walk(
        { red: 0, green: 0, blue: 0 },
        |round, color|
            when color is
                Red(n) -> { round & red: round.red + n }
                Green(n) -> { round & green: round.green + n }
                Blue(n) -> { round & blue: round.blue + n },
    )
    |> Ok

parse_color : Str -> Result [Red U64, Green U64, Blue U64] _
parse_color = |s|
    space = " " # avoid syntax highlighting issue
    s
    |> Str.trim
    |> Str.split_first(space)
    |> Result.map_err(|_| InvalidCubeSet(s))?
    |> |{ before, after }|
        n = Str.to_u64(before) ? |_| InvalidNumber(before)
        when after is
            "blue" -> Ok(Blue(n))
            "red" -> Ok(Red(n))
            "green" -> Ok(Green(n))
            _ -> Err(InvalidColor(after))

game_possible : Game, CubeSet -> Bool
game_possible = |game, bag|
    game.rounds
    |> List.all(
        |round|
            (round.red <= bag.red)
            and
            (round.green <= bag.green)
            and
            (round.blue <= bag.blue),
    )

## Solve part 2
part2 : Str -> Result Str _
part2 = |s|
    s
    |> Str.trim
    |> Str.split_on("\n")
    |> List.map_try(parse_game)?
    |> List.map(|game| minimum_cubes(game.rounds))
    |> List.map(|set| set_power(set))
    |> List.sum
    |> Num.to_str
    |> Ok

minimum_cubes : List CubeSet -> CubeSet
minimum_cubes = |rounds|
    rounds
    |> List.walk(
        { red: 0, green: 0, blue: 0 },
        |min, round| {
            red: Num.max(min.red, round.red),
            green: Num.max(min.green, round.green),
            blue: Num.max(min.blue, round.blue),
        },
    )

set_power : CubeSet -> U64
set_power = |set| set.red * set.green * set.blue
