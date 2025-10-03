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

## Run with `--linker legacy`
main! = |_args|
    AoC.solve!(
        {
            year: 2023,
            day: 6,
            title: "Wait For It",
            part1,
            part2,
        }
    )

## Solve part 1
part1 : Str -> Result Str _
part1 = |s| 
    parse_races(s)?
    |> List.map_try(|{ time, dist }| solve_for_time_pressed(dist, time))?
    |> List.map(|(t1, t2)| t2 - t1 + 1)
    |> List.product
    |> Num.to_str
    |> Ok

## Parse the input into a list of times and distances
parse_races :Str -> Result (List { time : U64, dist : U64 }) _
parse_races = |s|
    when Str.split_on(s, "\n") is
        [time_line, dist_line, ..] ->
            if Str.starts_with(time_line, "Time:      ") and Str.starts_with(dist_line, "Distance:  ") then
                time_str = Str.drop_prefix(time_line, "Time:      ")
                dist_str = Str.drop_prefix(dist_line, "Distance:  ")
                times = Str.split_on(time_str, " ") |> List.keep_oks(Str.to_u64)
                dists = Str.split_on(dist_str, " ") |> List.keep_oks(Str.to_u64)
                if List.len(times) != List.len(dists) then
                    Err(TimeDistanceMismatch("Mismatched time and distance counts"))
                else
                    List.map2(times, dists, |t, d| { time: t, dist: d }) |> Ok
            else
                Err(InvalidFormat("Input lines must start with 'Time:      ' and 'Distance:  '"))
        _ -> 
            Err(LessThanTwoLines("Input must have at least two lines"))


## Solve for the upper and lower bounds of time pressed to beat the best distance
solve_for_time_pressed : U64, U64 -> Result (U64, U64) _
solve_for_time_pressed = |dist_to_beat, race_duration|
    ## quadratic: time_pressed^2 + (-1 * race_duration) * time_pressed + dist_to_beat = 0
    a = 1.0
    b = -1 * Num.to_f64(race_duration)
    c = Num.to_f64(dist_to_beat)
    when quadratic_roots(a, b, c) is
        Ok((root1, root2)) -> 
            Ok((Num.floor(root1) + 1, Num.ceiling(root2) - 1))
        Err(e) -> 
            err_msg = "Error solving quadratic for time: ${Num.to_str(race_duration)}, dist: ${Num.to_str(dist_to_beat)}: ${Inspect.to_str(e)}"
            Err(ErrorSolvingQuadratic(err_msg))


## Solve the quadratic equation ax^2 + bx + c = 0 for real roots
quadratic_roots : F64, F64, F64 -> Result (F64, F64) [NoRealRoots, Overflow, DivByZero]
quadratic_roots = |a, b, c|
    discriminant = Num.sub_checked((b * b), (4 * a * c)) ? |Overflow| NoRealRoots
    if discriminant < 0 then
        Err(NoRealRoots)
    else
        sqrt_disc = Num.sqrt(discriminant)
        root1 = Num.div_checked(Num.sub_checked(-1 * b, sqrt_disc)?, (2 * a))?
        root2 = Num.div_checked(Num.add_checked(-1 * b, sqrt_disc)?, (2 * a))?
        Ok((root1, root2))
    

## Solve part 2
part2 : Str -> Result Str _
part2 = |s| 
    parse_single_race(s)?
    |> |{ time, dist }| solve_for_time_pressed(dist, time)
    |> Result.map_ok(|(t1, t2)| t2 - t1 + 1)
    |> Result.map_ok(Num.to_str)


## The text had bad kerning - parse all digits as a single number, ignoring spaces between digits
parse_single_race : Str -> Result { time : U64, dist : U64 } _
parse_single_race = |str|
    when Str.split_on(str, "\n") is
        [time_line, dist_line, ..] ->
            if Str.starts_with(time_line, "Time:      ") and Str.starts_with(dist_line, "Distance:  ") then
                time_str = Str.drop_prefix(time_line, "Time:      ")
                dist_str = Str.drop_prefix(dist_line, "Distance:  ")
                time = Str.split_on(time_str, " ") |> Str.join_with("") |> Str.to_u64?
                dist = Str.split_on(dist_str, " ") |> Str.join_with("") |> Str.to_u64?
                { time, dist } |> Ok
            else
                Err(InvalidFormat("Input lines must start with 'Time:      ' and 'Distance:  '"))
        _ -> 
            Err(LessThanTwoLines("Input must have at least two lines"))
