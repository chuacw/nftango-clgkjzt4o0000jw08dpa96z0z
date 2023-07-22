## Quest Features
initialize_game( ):
* Assert state is not already initialized.
* Opt into direct transfer of NFTs for the resource account and lock the game creator's NFT.
* Initialize the NFTangoStore resource and move it to the resource account.

cancel_game( ):
* Assert the state is correctly initialized.
* Assert that the game is active but no opponent has joined yet.
* Opt in the game creator for direct transfer and send back their NFT that was locked during game initialization.
* Deactivate the game.

join_game( ):
* Assert state is initialized and game is active
* Assert opponent NFT inputs are well formed and the join requirement is met.
* Create TokenIDs for each input and lock all of opponent's NFTs in the resource account.

play_game( ):
* Assert the state is initialized and the game is active and has an opponent.
* Set the outcome of the coin flip, however it is determined.
* Deactivate the game.

claim( ):
* Assert that state is initialized and game is not active.
* Assert a claim has not yet occurred and the claimer was a player in the game.
* Transfer all NFTs in resource account to winner.
* Set the has_claimed flag to true.
