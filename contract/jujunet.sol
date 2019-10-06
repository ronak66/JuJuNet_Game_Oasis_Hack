pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

contract tournament_creator {
    
    constructor () public {}
   
    enum GameState {DRAW_UNDECIDED, BETTING_OPEN, MATCH_IN_PROGRESS, GAME_OVER}
   
    struct Player{
        //bool alive;
        string name;
        string xyz;
        address player_address;
        uint256 current_match_id;
        uint256 current_bet;
        bool bet_placed;
    }
   
    struct Game {
        uint256 id;
        uint256 player1;
        uint256 player2;
        GameState state;
        uint256 player1_pool;
        uint256 player2_pool;
    }
   
    struct Tournament {
        uint256 id;
        address admin; // Creator of the tournament
        string name_description; // name of the tournament
        uint256 winner;
        bool tournament_over;
    }
    
    struct Spectet_Bet {
        address spectetor_add;
        uint256 value;
        uint256 tournament_id;
        uint256 match_id;
        uint256 bet_on;
    } 
   
    mapping(uint256 => Tournament) all_tournaments; // tournament.id ---> Tournament
    mapping(uint256 => mapping(uint256 => Game)) GameTree;   // tournament.id ---> gameId  ---> game
    mapping(uint256 => Player[]) Players_in_tournament;   // tournament.id ---> player_list
    mapping(uint256 => mapping(address => uint256)) player_index_lookup;   // tournament.id ---> player_list
    mapping(uint256 => mapping(uint256 => bool)) game_exsist;
    mapping(uint256 => bool) match_tree_created;
    mapping(uint256 => Spectet_Bet[]) bets_in_tournament;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Spectet_Bet))) spectet_bet_indexes;
    
    mapping(uint256 => mapping(address => uint256[])) spectetor_bets_in_tournament;
    mapping(uint256 => uint256) spectetor_bet_count;
    mapping(uint256 => uint256) playersRegistered;
    mapping(uint256 => mapping(uint256 => uint256[])) all_bets_in_match;
    mapping(uint256 => mapping(uint256 => uint256)) bets_in_match_count;
    mapping(uint256 => mapping(uint256 => uint256)) bets_in_match_count2;
    uint256 tournament_count = 0;
   
    function create_tournament(string memory name) public {
        Tournament memory new_tournament = Tournament({
            id: tournament_count,
            admin: msg.sender,
            name_description: name,
            winner: 0,
            tournament_over: false
        });
        all_tournaments[tournament_count] = new_tournament;
       
        playersRegistered[tournament_count] = 0;
       
        tournament_count++;
    }
   
   
    function add_player(uint256 tournament_id, string memory player_name, address playerAddress) public
    {
        Player memory temp_player = Player({
            name: player_name,
            xyz:player_name,
            player_address: playerAddress,
            current_match_id: 10000000,
            current_bet: 0,
            bet_placed: false
        });
       
        Players_in_tournament[tournament_id].push(temp_player);
       
        playersRegistered[tournament_id] += 1;
    }
       
   
   
    function create_match_tree(uint256 tournament_id) public returns (uint256, uint256, uint256) {
        
        uint256 n = playersRegistered[tournament_id];
        uint256 n1 = n - 1;
        uint256 sum = 0;

        uint256 counter = n - 1;
        uint256 compareVal =(n/2)-1;
        uint256 iter;
        uint256 nbar1 = n1 - 1;
        for (iter = counter; iter > compareVal; iter--){
                Game memory temp_game = Game({
                id: counter,
                player1: nbar1,
                player2: n1,
                state: GameState.BETTING_OPEN,
                player1_pool: 0,
                player2_pool: 0
            });
            n1 = n1 -2;
            nbar1 = nbar1 - 2;
            GameTree[tournament_id][iter - 1] = temp_game;
            game_exsist[tournament_id][iter-1] = true;    
        }
        return (sum, compareVal, counter);
    }
    function get_player_names(uint256 game_id,uint256 tournament_id) public view returns (string memory, string memory){
        return (Players_in_tournament[tournament_id][GameTree[tournament_id][game_id].player1].xyz, Players_in_tournament[tournament_id][GameTree[tournament_id][game_id].player2].xyz);
    }
    
   
    function getPlayer() public view returns (string memory) {
        return (Players_in_tournament[0][0].xyz);
       
    }
    
    function transferValue(address _to, uint256 value) public{
        _to.call.value(value).gas(1000)("");   
    }
    

    function decide_match(uint256 tournament_id,uint256 match_id, uint256 decision) public returns (string memory) {
        require(msg.sender == all_tournaments[tournament_id].admin);
        require(GameTree[tournament_id][match_id].state != GameState.GAME_OVER);
        uint256 winner;
        uint256 losser;
        uint256 winner_amount;
        uint256 losser_amount;
        if(decision == 1){
            winner = GameTree[tournament_id][match_id].player1;    
            losser = GameTree[tournament_id][match_id].player2;
            winner_amount = Players_in_tournament[tournament_id][winner].current_bet;
            losser_amount = Players_in_tournament[tournament_id][losser].current_bet;
        }
        else{
            winner = GameTree[tournament_id][match_id].player2;
            losser = GameTree[tournament_id][match_id].player1;
            winner_amount = Players_in_tournament[tournament_id][winner].current_bet;
            losser_amount = Players_in_tournament[tournament_id][losser].current_bet;
        }
        if(match_id == 0){
            all_tournaments[tournament_id].winner = winner;
            all_tournaments[tournament_id].tournament_over = true;
        }
        else{
            uint256 parent_id;
            if(match_id%2 == 0){
                parent_id = (match_id/2) -1;
            }
            else{
                parent_id = (match_id/2);
            }
            if(game_exsist[tournament_id][parent_id]){
                if(match_id%2 == 0){
                    GameTree[tournament_id][parent_id].player2 = winner;
                }
                else{
                    GameTree[tournament_id][parent_id].player1 = winner;
                }
                GameTree[tournament_id][parent_id].state = GameState.BETTING_OPEN;
            }
            else{
                Game memory temp_game = Game({
                    id: parent_id,
                    player1: winner,
                    player2: winner,
                    state: GameState.DRAW_UNDECIDED,
                    player1_pool: 0,
                    player2_pool: 0
                });
                GameTree[tournament_id][parent_id] = temp_game;
                game_exsist[tournament_id][parent_id] = true;
            }
        }
        GameTree[tournament_id][match_id].state = GameState.GAME_OVER;
        transferValue(Players_in_tournament[tournament_id][winner].player_address, winner_amount+losser_amount);
        Players_in_tournament[tournament_id][winner].bet_placed = false;
        Players_in_tournament[tournament_id][winner].current_bet = 0;
        Players_in_tournament[tournament_id][losser].bet_placed = false;
        Players_in_tournament[tournament_id][losser].current_bet = 0;
        return Players_in_tournament[tournament_id][winner].xyz;
    }
    
    function player_place_bet(uint256 tournament_id, uint256 match_id) public payable returns (string memory, uint256 ){
        require(GameTree[tournament_id][match_id].state == GameState.BETTING_OPEN);
        bool isPlayer1 = (msg.sender == Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player1].player_address);
        bool isPlayer2 = (msg.sender == Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player2].player_address);
        require( isPlayer1 || isPlayer2);
        if (isPlayer1) {
            Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player1].current_bet = msg.value;
            //Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player1].bet_placed = true;
            return (Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player1].xyz, msg.value);
        }
        else{
            Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player2].current_bet = msg.value;
            //Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player2].bet_placed = true;
            return (Players_in_tournament[tournament_id][GameTree[tournament_id][match_id].player2].xyz, msg.value);
        }
    }
    
    function get_player_bets(uint256 index) public view returns(string memory, uint256) {
        return(Players_in_tournament[0][index].xyz, Players_in_tournament[0][index].current_bet);
    }
    
    function place_spectetor_bet(uint256 _tournament_id, uint256 _match_id, uint256 player_index) public payable {
        require(GameTree[_tournament_id][_match_id].state == GameState.BETTING_OPEN);
        uint256 player1_pool = GameTree[_tournament_id][_match_id].player1_pool;
        uint256 player2_pool = GameTree[_tournament_id][_match_id].player2_pool;
        uint256 player1_bet = Players_in_tournament[_tournament_id][GameTree[_tournament_id][_match_id].player1].current_bet;
        uint256 player2_bet = Players_in_tournament[_tournament_id][GameTree[_tournament_id][_match_id].player2].current_bet;
        if(player_index == 1){
            require(player1_pool+msg.value<=player1_bet);
            GameTree[_tournament_id][_match_id].player1_pool+=msg.value;
        }
        else{
            require(player2_pool+msg.value<=player2_bet);
            GameTree[_tournament_id][_match_id].player2_pool+=msg.value;
        }
        Spectet_Bet memory temp_bet = Spectet_Bet({
            spectetor_add: msg.sender,
            tournament_id: _tournament_id,
            match_id: _match_id,
            value: msg.value,
            bet_on: player_index
        });
        Spectet_Bet memory temp_bet2 = Spectet_Bet({
            spectetor_add: msg.sender,
            tournament_id: _tournament_id,
            match_id: _match_id,
            value: msg.value,
            bet_on: player_index
        });
        
        spectet_bet_indexes[_tournament_id][_match_id][bets_in_match_count2[_tournament_id][_match_id]] = temp_bet2;
        bets_in_tournament[_tournament_id].push(temp_bet);
        all_bets_in_match[_tournament_id][_match_id].push(spectetor_bet_count[_tournament_id]);
        bets_in_match_count[_tournament_id][_match_id] += 1;
        bets_in_match_count2[_tournament_id][_match_id] += 1;
        spectetor_bets_in_tournament[_tournament_id][msg.sender].push(spectetor_bet_count[_tournament_id]);
        spectetor_bet_count[_tournament_id]+=1;
    }
    
    function get_spectetor_bet(uint256 tournament_id, uint256 bet_index) public view returns (uint256,uint256) {
        uint256 index_of_bets_in_tournamenet = spectetor_bets_in_tournament[tournament_id][msg.sender][bet_index];
        uint256 bet_value = bets_in_tournament[tournament_id][index_of_bets_in_tournamenet].value;
        uint256 bet_match_index = bets_in_tournament[tournament_id][index_of_bets_in_tournamenet].match_id;
        return (bet_value,bet_match_index);
    }
    
    function decide_match2(uint256 tournament_id,uint256 match_id, uint256 decision) public returns (string memory) {
        require(msg.sender == all_tournaments[tournament_id].admin);
        require(GameTree[tournament_id][match_id].state != GameState.GAME_OVER);
        uint256 winner;
        uint256 losser;
        uint256 winner_pool;
        uint256 losser_pool;
        if(decision == 1){
            winner = GameTree[tournament_id][match_id].player1;    
            losser = GameTree[tournament_id][match_id].player2;
            winner_pool = Players_in_tournament[tournament_id][winner].current_bet+GameTree[tournament_id][match_id].player1_pool;
            losser_pool = Players_in_tournament[tournament_id][losser].current_bet+GameTree[tournament_id][match_id].player2_pool;
        }
        else{
            winner = GameTree[tournament_id][match_id].player2;
            losser = GameTree[tournament_id][match_id].player1;
            winner_pool = Players_in_tournament[tournament_id][winner].current_bet+GameTree[tournament_id][match_id].player2_pool;
            losser_pool = Players_in_tournament[tournament_id][losser].current_bet+GameTree[tournament_id][match_id].player1_pool;
        }
        if(match_id == 0){
            all_tournaments[tournament_id].winner = winner;
            all_tournaments[tournament_id].tournament_over = true;
        }
        else{
            uint256 parent_id;
            if(match_id%2 == 0){
                parent_id = (match_id/2) -1;
            }
            else{
                parent_id = (match_id/2);
            }
            if(game_exsist[tournament_id][parent_id]){
                if(match_id%2 == 0){
                    GameTree[tournament_id][parent_id].player2 = winner;
                }
                else{
                    GameTree[tournament_id][parent_id].player1 = winner;
                }
                GameTree[tournament_id][parent_id].state = GameState.BETTING_OPEN;
            }
            else{
                Game memory temp_game = Game({
                    id: parent_id,
                    player1: winner,
                    player2: winner,
                    state: GameState.DRAW_UNDECIDED,
                    player1_pool: 0,
                    player2_pool: 0
                });
                GameTree[tournament_id][parent_id] = temp_game;
                game_exsist[tournament_id][parent_id] = true;
            }
        }
        GameTree[tournament_id][match_id].state = GameState.GAME_OVER;
        
        
        //uint256 (winner_pool+losser_pool)) = winner_pool + losser_pool;
        //winning_player
        uint256 winner_prize = (Players_in_tournament[tournament_id][winner].current_bet * 96 * (winner_pool+losser_pool)) / (100 * winner_pool);
        transferValue(Players_in_tournament[tournament_id][winner].player_address, winner_prize);
        /*
        uint256 spectator_winnings;        
        uint256 temp = tournament_id;
        uint256 spectator_index;
        uint256 spectator_bet_index;
        for(spectator_index = 0; spectator_index < bets_in_match_count[temp][match_id]; spectator_index++){
            spectator_bet_index = get_spec_bet_index(temp,match_id,spectator_index);
            if(bet_result(temp,match_id,spectator_bet_index) == winner){
                spectator_winnings = (96*bets_in_tournament[temp][spectator_bet_index].value*(winner_pool+losser_pool))/(100*winner_pool);
                transferValue(bets_in_tournament[temp][spectator_bet_index].spectetor_add,spectator_winnings);
            }
        }
        */
        
        //process_spectator_bets(tournament_id, match_id, winner, (winner_pool + losser_pool), winner_pool);
        uint256 prizezz;
        for(uint256 i=0;i<bets_in_match_count2[tournament_id][match_id];i++){
            prizezz = (spectet_bet_indexes[tournament_id][match_id][i].value*96*(losser_pool+winner_pool))/(100*winner_pool);
            if(get_bet_on(tournament_id,spectet_bet_indexes[tournament_id][match_id][i].bet_on,match_id)==winner){
                transferValue(spectet_bet_indexes[tournament_id][match_id][i].spectetor_add,prizezz);
            }
        }
        
        
        Players_in_tournament[tournament_id][winner].bet_placed = false;
        Players_in_tournament[tournament_id][winner].current_bet = 0;
        Players_in_tournament[tournament_id][losser].bet_placed = false;
        Players_in_tournament[tournament_id][losser].current_bet = 0;
        return Players_in_tournament[tournament_id][winner].xyz;
    }
    
    function process_spectator_bets(uint256 tournament_id, uint256 match_id, uint256 winner, uint256 totalPool, uint256 winnerPool) private {
        uint256 cap = bets_in_match_count[tournament_id][match_id];
        uint256 bet_index;
        uint256 outcome;
        uint256 prize;
        for(uint256 i = 0; i < cap; i++){
            bet_index = all_bets_in_match[tournament_id][match_id][i];
            outcome = get_bet_on(tournament_id, bets_in_tournament[tournament_id][bet_index].bet_on,match_id);
            if (outcome == winner){
                prize = (bets_in_tournament[tournament_id][bet_index].value  * 96 * totalPool) / (100 * winnerPool);
                transferValue(bets_in_tournament[tournament_id][bet_index].spectetor_add, prize);
                
                
                
            }
        }
    }
    
    function get_bet_on(uint256 tournament_id,uint256 bet_on, uint256 match_id) private view returns(uint256){
        if(bet_on == 1){
            return GameTree[tournament_id][match_id].player1;
        }
        else{
            return GameTree[tournament_id][match_id].player2;
        }
    }
    
    function get_spec_bet_index(uint256 tournament_id,uint256 match_id,uint256 spec_index) private view returns(uint256){
        return all_bets_in_match[tournament_id][match_id][spec_index];
    }
    
    function bet_result(uint256 tournament_id,uint256 match_id,uint256 spec_bet_index) private view returns(uint256){
        return get_bet_on(tournament_id,bets_in_tournament[tournament_id][spec_bet_index].bet_on, match_id);
    }
}  
