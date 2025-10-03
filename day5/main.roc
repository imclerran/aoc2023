app [main!] {
    cli: platform "https://github.com/roc-lang/basic-cli/releases/download/0.20.0/X73hGh05nNTkDHU06FHC0YfFaQB1pimX7gncRcao5mU.tar.br",
    aoc: "../../aoc-template/package/main.roc",
    rtils: "https://github.com/imclerran/rtils/releases/download/v0.1.7/xGdIJGyOChqLXjqx99Iqunxz3XyEpBp5zGOdb3OVUhs.tar.br",
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
    AoC.solve!
        (
            {
                year: 2023,
                day: 5,
                title: "If You Give A Seed A Fertilizer",
                part1,
                part2,
            }
        )

part1 : Str -> Result Str _
part1 = |s|
    (seeds, rest1) = parse_seeds(s)
    (seeds_to_soil, rest2) = parse_map(rest1, "seed-to-soil")
    (soil_to_fert, rest3) = parse_map(rest2, "soil-to-fertilizer")
    (fert_to_water, rest4) = parse_map(rest3, "fertilizer-to-water")
    (water_to_light, rest5) = parse_map(rest4, "water-to-light")
    (light_to_temp, rest6) = parse_map(rest5, "light-to-temperature")
    (temp_to_humid, rest7) = parse_map(rest6, "temperature-to-humidity")
    (humid_to_loc, _) = parse_map(rest7, "humidity-to-location")

    List.map(
        seeds,
        |seed|
            seed
            |> apply_map(seeds_to_soil)
            |> apply_map(soil_to_fert)
            |> apply_map(fert_to_water)
            |> apply_map(water_to_light)
            |> apply_map(light_to_temp)
            |> apply_map(temp_to_humid)
            |> apply_map(humid_to_loc),
    )
    |> List.min
    |> Result.map_ok(Num.to_str)

parse_seeds = |s|
    when Str.split_first(s, "\n") is
        Ok({ before: line, after: rest }) ->
            when Str.split_on(line, ": ") is
                [_, seed_strs] ->
                    seeds = Str.split_on(seed_strs, " ") |> List.keep_oks(Str.to_u64)
                    (seeds, rest)

                _ -> ([], rest)

        _ -> ([], s)

parse_map = |s, name|
    help = |rem, maps|
        when Str.split_first(rem, "\n") is
            Ok({ before: line, after: rest }) ->
                when Str.split_on(line, " ") |> List.keep_oks(Str.to_u64) is
                    [dest, source, range] ->
                        new_maps = List.append(maps, { dest, source, range })
                        help(rest, new_maps)

                    _ -> (maps, rest)

            _ -> (maps, s)

    trimmed = Str.trim_start(s)
    if Str.starts_with(trimmed, "${name} map:\n") then
        Str.drop_prefix(trimmed, "${name} map:\n") |> help([])
    else
        ([], s)

apply_map = |value, map_entries|
    in_source_range = |map_entry, val|
        val >= map_entry.source and val <= (map_entry.source + map_entry.range)

    transform_value = |map_entry, val| map_entry.dest + (val - map_entry.source)

    List.walk_until(
        map_entries,
        value,
        |v, entry|
            if in_source_range(entry, v) then
                Break(transform_value(entry, v))
            else
                Continue(v),
    )

part2 : Str -> Result Str _
part2 = |s|
    (pairs, rest1) = parse_seed_pairs(s)
    (seeds_to_soil, rest2) = parse_map(rest1, "seed-to-soil")
    (soil_to_fert, rest3) = parse_map(rest2, "soil-to-fertilizer")
    (fert_to_water, rest4) = parse_map(rest3, "fertilizer-to-water")
    (water_to_light, rest5) = parse_map(rest4, "water-to-light")
    (light_to_temp, rest6) = parse_map(rest5, "light-to-temperature")
    (temp_to_humid, rest7) = parse_map(rest6, "temperature-to-humidity")
    (humid_to_loc, _) = parse_map(rest7, "humidity-to-location")

    maps = {
        seeds_to_soil,
        soil_to_fert,
        fert_to_water,
        water_to_light,
        light_to_temp,
        temp_to_humid,
        humid_to_loc,
    }
    iterate_seed_pairs(pairs, maps) |> Num.to_str |> Ok


parse_seed_pairs = |s|
    (numbers, rest) = parse_seeds(s)
    pairs =
        numbers
        |> List.chunks_of(2)
        |> List.keep_oks(
            |pair|
                when pair is
                    [start, range] -> Ok{ start, range }
                    _ -> Err(InvalidPair)
        )
    (pairs, rest)


iterate_seed_pairs = |pairs, maps|
    List.walk(pairs, Num.max_u64, |pairs_min, pair|
        List.range({start: At(pair.start), end: Length(pair.range)})
        |> List.walk(pairs_min, |range_min, seed|
            seed
            |> apply_map(maps.seeds_to_soil)
            |> apply_map(maps.soil_to_fert)
            |> apply_map(maps.fert_to_water)
            |> apply_map(maps.water_to_light)
            |> apply_map(maps.light_to_temp)
            |> apply_map(maps.temp_to_humid)
            |> apply_map(maps.humid_to_loc)
            |> Num.min(range_min)
        )
        |> Num.min(pairs_min)
    )