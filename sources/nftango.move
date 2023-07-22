module overmind::nftango {
    use std::option::Option;
    use std::string::String;

    use aptos_framework::account;

    use std::signer;
    use std::option;
    use std::vector;
    use aptos_token::token::{Self, create_token_id_raw, TokenId};

    //
    // Errors
    //
    const ERROR_NFTANGO_STORE_EXISTS: u64 = 0;
    const ERROR_NFTANGO_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_NFTANGO_STORE_IS_ACTIVE: u64 = 2;
    const ERROR_NFTANGO_STORE_IS_NOT_ACTIVE: u64 = 3;
    const ERROR_NFTANGO_STORE_HAS_AN_OPPONENT: u64 = 4;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT: u64 = 5;
    const ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET: u64 = 6;
    const ERROR_NFTS_ARE_NOT_IN_THE_SAME_COLLECTION: u64 = 7;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN: u64 = 8;
    const ERROR_NFTANGO_STORE_HAS_CLAIMED: u64 = 9;
    const ERROR_NFTANGO_STORE_IS_NOT_PLAYER: u64 = 10;
    const ERROR_VECTOR_LENGTHS_NOT_EQUAL: u64 = 11;

    const SEED: vector<u8> = x"01";

    //
    // Data structures
    //
    struct NFTangoStore has key {
        creator_token_id: TokenId,
        // The number of NFTs (one or more) from the same collection that the opponent needs to bet to enter the game
        join_amount_requirement: u64,
        opponent_address: Option<address>,
        opponent_token_ids: vector<TokenId>,
        active: bool,
        has_claimed: bool,
        did_creator_win: Option<bool>,
        signer_capability: account::SignerCapability
    }

    //
    // Assert functions
    //
    public fun assert_nftango_store_exists(
        account_address: address,
    ) {
        // DONE: assert that `NFTangoStore` exists
        assert!(exists<NFTangoStore>(account_address), ERROR_NFTANGO_STORE_DOES_NOT_EXIST)
    }

    public fun assert_nftango_store_does_not_exist(
        account_address: address,
    ) {
        // DONE: assert that `NFTangoStore` does not exist
        assert!(!exists<NFTangoStore>(account_address), ERROR_NFTANGO_STORE_EXISTS)
    }

    public fun assert_nftango_store_is_active(
        account_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.active` is active
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(nftango_store.active, ERROR_NFTANGO_STORE_IS_NOT_ACTIVE)
    }

    public fun assert_nftango_store_is_not_active(
        account_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.active` is not active
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(!nftango_store.active, ERROR_NFTANGO_STORE_IS_ACTIVE)
    }

    public fun assert_nftango_store_has_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.opponent_address` is set
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(!option::is_none(&nftango_store.opponent_address), ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT)
    }

    public fun assert_nftango_store_does_not_have_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.opponent_address` is not set
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(option::is_none(&nftango_store.opponent_address), ERROR_NFTANGO_STORE_HAS_AN_OPPONENT)
    }

    public fun assert_nftango_store_join_amount_requirement_is_met(
        game_address: address,
        token_ids: vector<TokenId>,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.join_amount_requirement` is met
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(nftango_store.join_amount_requirement == vector::length(&token_ids), ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET)
    }

    public fun assert_nftango_store_has_did_creator_win(
        game_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.did_creator_win` is set
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(option::is_some(&nftango_store.did_creator_win), ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN)
    }

    public fun assert_nftango_store_has_not_claimed(
        game_address: address,
    ) acquires NFTangoStore {
        // DONE: assert that `NFTangoStore.has_claimed` is false
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(!nftango_store.has_claimed, ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN)
    }

    public fun assert_nftango_store_is_player(account_address: address, game_address: address) acquires NFTangoStore {
        // DONE: assert that `account_address` is either the equal to `game_address` or `NFTangoStore.opponent_address`
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!((account_address == game_address) ||
                (option::contains(&nftango_store.opponent_address, &account_address)),
            ERROR_NFTANGO_STORE_HAS_CLAIMED)
    }

    public fun assert_vector_lengths_are_equal(creator: vector<address>,
                                               collection_name: vector<String>,
                                               token_name: vector<String>,
                                               property_version: vector<u64>) {
        // DONE: assert all vector lengths are equal
        let creator_len = vector::length(&creator);
        let token_name_len = vector::length(&token_name);
        assert!( (creator_len == token_name_len) &&
                 (creator_len == vector::length(&collection_name)) &&
                 (token_name_len == vector::length(&property_version)),
                ERROR_VECTOR_LENGTHS_NOT_EQUAL)
    }

    //
    // Entry functions
    //
    public entry fun initialize_game(
        account: &signer,               // creator
        creator: address,               // nft_creator
        collection_name: String,        // nft_collection_name
        token_name: String,             // nft_token_name
        property_version: u64,
        join_amount_requirement: u64
    ) {
        // DONE: run assert_nftango_store_does_not_exist
        let creator_address = signer::address_of(account);
        assert_nftango_store_does_not_exist(creator_address);

        // DONE: create resource account
        let (resource, resource_signer_cap) = account::create_resource_account(account, SEED);
        let resource_addr = signer::address_of(&resource);
        let resource_signer = account::create_signer_with_capability(&resource_signer_cap);

        // DONE: token::create_token_id_raw
        let creator_token_id = token::create_token_id_raw(creator, collection_name, token_name, property_version);

        // DONE: opt in to direct transfer for resource account
        token::opt_in_direct_transfer(&resource_signer, true);

        // DONE: transfer NFT to resource account
        token::transfer(account, creator_token_id, resource_addr, 1);

        // DONE: move_to resource `NFTangoStore` to account signer
        move_to(
            account,
            NFTangoStore {
                creator_token_id,
                join_amount_requirement,
                opponent_address: option::none<address>(),
                opponent_token_ids: vector::empty<TokenId>(),
                active: true,
                has_claimed: false,
                did_creator_win: option::none<bool>(),
                signer_capability: resource_signer_cap
            }
        );
    }

    /*

    */
    public entry fun cancel_game(
        account: &signer,
    ) acquires NFTangoStore {
        // DONE: run assert_nftango_store_exists
        let nft_store_address = signer::address_of(account);
        assert_nftango_store_exists(nft_store_address);

        // DONE: run assert_nftango_store_is_active
        assert_nftango_store_is_active(nft_store_address);

        // DONE: run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(nft_store_address);

        // DONE: opt in to direct transfer for account
        token::opt_in_direct_transfer(account, true);

        // DONE: transfer NFT to account address
        let nft_store = borrow_global_mut<NFTangoStore>(nft_store_address);
        let resource_signer = account::create_signer_with_capability(&nft_store.signer_capability);
        token::transfer(&resource_signer, nft_store.creator_token_id, nft_store_address, 1);

        // DONE: set `NFTangoStore.active` to false
        nft_store.active = false
    }

    public fun join_game(
        account: &signer,
        game_address: address,
        creators: vector<address>,
        collection_names: vector<String>,
        token_names: vector<String>,
        property_versions: vector<u64>,
    ) acquires NFTangoStore {
        // DONE: run assert_vector_lengths_are_equal
        assert_vector_lengths_are_equal(creators, collection_names, token_names, property_versions);

        // DONE: loop through and create token_ids vector<TokenId>
        let token_ids = vector::empty<TokenId>();
        let i = 0; let creators_len = vector::length(&creators);
        while (i < creators_len) {
            let creator = *vector::borrow(&creators, i);
            let collection_name = *vector::borrow(&collection_names, i);
            let token_name = *vector::borrow(&token_names, i);
            let property_version = *vector::borrow(&property_versions, i);
            let creator_token_id = create_token_id_raw(creator, collection_name, token_name, property_version);
            vector::push_back(&mut token_ids, creator_token_id);
            i = i + 1
        };

        // DONE: run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // DONE: run assert_nftango_store_is_active
        assert_nftango_store_is_active(game_address);

        // DONE: run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(game_address);

        // DONE: run assert_nftango_store_join_amount_requirement_is_met
        assert_nftango_store_join_amount_requirement_is_met(game_address, token_ids);

        // DONE: loop through token_ids and transfer each NFT to the resource account
        let nft_store = borrow_global_mut<NFTangoStore>(game_address);
        let resource_signer = account::create_signer_with_capability(&nft_store.signer_capability);
        i = 0;
        let resource_signer_address = signer::address_of(&resource_signer);
        let token_len = vector::length(&token_ids);
        while (i < token_len) {
            let token_id = *vector::borrow(&token_ids, i);
            token::transfer(account, token_id, resource_signer_address, 1);
            i = i + 1
        };

        // DONE: set `NFTangoStore.opponent_address` to account_address
        let account_address = signer::address_of(account);
        option::fill<address>(&mut nft_store.opponent_address, account_address);

        // DONE: set `NFTangoStore.opponent_token_ids` to token_ids
        nft_store.opponent_token_ids = token_ids
    }

    public entry fun play_game(account: &signer, did_creator_win: bool) acquires NFTangoStore {
        // DONE: run assert_nftango_store_exists
        let nft_store_address = signer::address_of(account);
        assert_nftango_store_exists(nft_store_address);

        // DONE: run assert_nftango_store_is_active
        assert_nftango_store_is_active(nft_store_address);

        // DONE: run assert_nftango_store_has_an_opponent
        assert_nftango_store_has_an_opponent(nft_store_address);

        // DONE: set `NFTangoStore.did_creator_win` to did_creator_win
        let nft_store = borrow_global_mut<NFTangoStore>(nft_store_address);
        option::fill(&mut nft_store.did_creator_win, did_creator_win);

        // DONE: set `NFTangoStore.active` to false
        nft_store.active = false
    }


    public entry fun claim(account: &signer, game_address: address) acquires NFTangoStore {
        // DONE: run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // DONE: run assert_nftango_store_is_not_active
        assert_nftango_store_is_not_active(game_address);

        // DONE: run assert_nftango_store_has_not_claimed
        assert_nftango_store_has_not_claimed(game_address);

        // DONE: run assert_nftango_store_is_player
        let account_address = signer::address_of(account);
        assert_nftango_store_is_player(account_address, game_address);

        // TODO: if the player won, send them all the NFTs
        let nft_store = borrow_global_mut<NFTangoStore>(game_address);
        let resource_signer = account::create_signer_with_capability(&nft_store.signer_capability);

        let winner_address: address;
        if (option::contains(&nft_store.did_creator_win, &true)) {
            winner_address = account_address;
        } else {
            winner_address = *option::borrow<address>(&nft_store.opponent_address);
        };
        let i = 0; let nft_length = vector::length(&nft_store.opponent_token_ids);
        while (i < nft_length) {
            let token_id = *vector::borrow(&nft_store.opponent_token_ids, i);
            token::transfer(&resource_signer, token_id, winner_address, 1);
            i = i + 1
        };
        token::transfer(&resource_signer, nft_store.creator_token_id, winner_address, 1);

        // DONE: set `NFTangoStore.has_claimed` to true
        nft_store.has_claimed = true
    }
}