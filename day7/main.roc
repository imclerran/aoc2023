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
            day: 7,
            title: "Camel Cards",
            part1,
            part2,
        },
    )

Hand : [FiveOfAKind Str, FourOfAKind Str, FullHouse Str, ThreeOfAKind Str, TwoPair Str, OnePair Str, HighCard Str]

## Solve part 1
part1 : Str -> Result Str [InvalidBid Str, InvalidHand Str]
part1 = |s|
    Str.trim_end(s)
    |> Str.split_on("\n")
    |> List.map_try(parse_hand)?
    |> List.sort_with(compare_hand_bets)
    |> List.walk_with_index(0, |sum, (_, bet), i| sum + bet * (i + 1))
    |> Num.to_str
    |> Ok

parse_hand : Str -> Result (Hand, U64) [InvalidHand Str, InvalidBid Str]
parse_hand = |str|
    { before: hand_str, after: bid_str } = Str.split_first(str, " ") ? |_| InvalidHand(str)
    bid = Str.to_u64(bid_str) ? |_| InvalidBid(bid_str)
    hand =
        Str.to_utf8(hand_str)
        |> List.walk(
            Dict.empty({}),
            |cards, c|
                when Dict.get(cards, c) is
                    Ok(count) -> Dict.insert(cards, c, count + 1)
                    Err(KeyNotFound) -> Dict.insert(cards, c, 1),
        )
        |> Dict.to_list
        |> List.walk(HighCard(hand_str), |type, (_, count)| transform_hand(type, count))
    Ok((hand, bid))

transform_hand : Hand, U8 -> Hand
transform_hand = |hand, count|
    when (hand, count) is
        (HighCard(s), 5) -> FiveOfAKind(s)
        (HighCard(s), 4) -> FourOfAKind(s)
        (HighCard(s), 3) -> ThreeOfAKind(s)
        (HighCard(s), 2) -> OnePair(s)
        (HighCard(s), 1) -> HighCard(s)
        (OnePair(s), 3) -> FullHouse(s)
        (OnePair(s), 2) -> TwoPair(s)
        (ThreeOfAKind(s), 2) -> FullHouse(s)
        _ -> hand

compare_hand_bets : (Hand, U64), (Hand, U64) -> [LT, EQ, GT]
compare_hand_bets = |(h1, _), (h2, _)| compare_hands(h1, h2)

compare_hands : Hand, Hand -> [LT, EQ, GT]
compare_hands = |h1, h2|
    r1 = rank_hand(h1)
    r2 = rank_hand(h2)
    if r1 < r2 then
        LT
    else if r1 > r2 then
        GT
    else
        List.map2(get_hand_cards(h1), get_hand_cards(h2), |c1, c2| (c1, c2))
        |> List.walk_until(
            EQ,
            |_, (c1, c2)|
                when compare_cards(c1, c2) is
                    EQ -> Continue(EQ)
                    comp -> Break(comp),
        )

compare_cards : U8, U8 -> [LT, EQ, GT]
compare_cards = |c1, c2|
    (r1, r2) = (rank_card(c1), rank_card(c2))
    if r1 == r2 then EQ else if r1 < r2 then LT else GT

rank_card : U8 -> U8
rank_card = |card|
    when card is
        'A' -> 14
        'K' -> 13
        'Q' -> 12
        'J' -> 11
        'T' -> 10
        c if c >= '2' and c <= '9' -> c - '0'
        _ -> 0

get_hand_cards : Hand -> List U8
get_hand_cards = |hand|
    when hand is
        HighCard(s) | OnePair(s) | TwoPair(s) | ThreeOfAKind(s) | FullHouse(s) | FourOfAKind(s) | FiveOfAKind(s) -> Str.to_utf8(s)

rank_hand : Hand -> U8
rank_hand = |hand|
    when hand is
        HighCard(_) -> 0
        OnePair(_) -> 1
        TwoPair(_) -> 2
        ThreeOfAKind(_) -> 3
        FullHouse(_) -> 4
        FourOfAKind(_) -> 5
        FiveOfAKind(_) -> 6

## Solve part 2
part2 : Str -> Result Str [InvalidBid Str, InvalidHand Str]
part2 = |s|
    Str.trim_end(s)
    |> Str.split_on("\n")
    |> List.map_try(parse_joker_hand)?
    |> List.sort_with(compare_joker_hand_bets)
    |> List.walk_with_index(0, |sum, (_, bet), i| sum + bet * (i + 1))
    |> Num.to_str
    |> Ok

parse_joker_hand : Str -> Result (Hand, U64) [InvalidHand Str, InvalidBid Str]
parse_joker_hand = |str|
    { before: hand_str, after: bid_str } = Str.split_first(str, " ") ? |_| InvalidHand(str)
    bid = Str.to_u64(bid_str) ? |_| InvalidBid(bid_str)
    hand_with_jokers =
        Str.to_utf8(hand_str)
        |> List.walk(
            Dict.empty({}),
            |cards, c|
                when Dict.get(cards, c) is
                    Ok(count) -> Dict.insert(cards, c, count + 1)
                    Err(KeyNotFound) -> Dict.insert(cards, c, 1),
        )
        |> Dict.to_list
        |> List.walk(
            { hand: HighCard(hand_str), jokers: 0 },
            |hj, (c, count)|
                if c == 'J' then
                    { hj & jokers: count }
                else
                    { hj & hand: transform_hand(hj.hand, count) }
        )
    Ok((best_hand(hand_with_jokers), bid))

HandWithJokers : {
    hand : Hand,
    jokers : U8,
}

best_hand : HandWithJokers -> Hand
best_hand = |uh|
    when (uh.hand, uh.jokers) is
        (FourOfAKind(s), 1) -> FiveOfAKind(s)
        (ThreeOfAKind(s), 2) -> FiveOfAKind(s)
        (ThreeOfAKind(s), 1) -> FourOfAKind(s)
        (TwoPair(s), 1) -> FullHouse(s)
        (OnePair(s), 3) -> FiveOfAKind(s)
        (OnePair(s), 2) -> FourOfAKind(s)
        (OnePair(s), 1) -> ThreeOfAKind(s)
        (HighCard(s), 5) -> FiveOfAKind(s)
        (HighCard(s), 4) -> FiveOfAKind(s)
        (HighCard(s), 3) -> FourOfAKind(s)
        (HighCard(s), 2) -> ThreeOfAKind(s)
        (HighCard(s), 1) -> OnePair(s)
        _ -> uh.hand

compare_joker_hand_bets : (Hand, U64), (Hand, U64) -> [LT, EQ, GT]
compare_joker_hand_bets = |(h1, _), (h2, _)| compare_joker_hands(h1, h2)

compare_joker_hands : Hand, Hand -> [LT, EQ, GT]
compare_joker_hands = |h1, h2|
    (r1, r2) = (rank_hand(h1), rank_hand(h2))
    if r1 < r2 then
        LT
    else if r1 > r2 then
        GT
    else
        List.map2(get_hand_cards(h1), get_hand_cards(h2), |c1, c2| (c1, c2))
        |> List.walk_until(
            EQ,
            |_, (c1, c2)|
                when compare_joker_cards(c1, c2) is
                    EQ -> Continue(EQ)
                    comp -> Break(comp),
        )

compare_joker_cards : U8, U8 -> [LT, EQ, GT]
compare_joker_cards = |c1, c2|
    (r1, r2) = (rank_joker_card(c1), rank_joker_card(c2))
    if r1 == r2 then EQ else if r1 < r2 then LT else GT

rank_joker_card : U8 -> U8
rank_joker_card = |card| if card == 'J' then 1 else rank_card(card)
