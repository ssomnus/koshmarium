const regButton = document.getElementById("regBut");
const signButton = document.getElementById("signBut");
const start = document.querySelector(".main");
const roomList = document.querySelector(".rooms");
const crRoomButton = document.querySelector(".cr-room");
const countPlayer = document.querySelector(".cplayer-value");
const moveTime = document.querySelector(".tmove-value");
const moveTimeValue = document.getElementById('time-move');
const countPlayerValue = document.getElementById('count-player')

moveTimeValue.addEventListener('input',function (){
    moveTime.innerHTML = moveTimeValue.value;
})

countPlayerValue.addEventListener('input',function (){
    countPlayer.innerHTML = countPlayerValue.value;
})

for (let e of document.getElementsByClassName('card')){
    e.addEventListener('click',function (){
        if (cardChoosing){
            if (!this.classList.contains('filled') && this.classList.contains('pl1')){
                chosenCard = this.classList[2].slice(-2);
                cardChoosing = false;
                cardPut()
            }
        }
    })
}

let inWaitingRoom = false;
let showRoom = true;
let token;
let room_id;
let player_id;
let login;
let cards = [];
let monsters = [];
let players = [];
let cardChoosing = false;
let chosenCard = -1;
let timerQ;
let seconds;
let chosenCards = [];
let placeCardChoosing = false;
let placeCardChosen = false;
let chosenCard2 = [];
let placeCardChoosing2 = false;
let placeCardChosen2 = false;


function signin() {
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();

    fd.append("pname", "SignIn");
    fd.append("db", "265117");
    fd.append("p1", document.getElementById("log1").value);
    fd.append("p2", document.getElementById("pas1").value);
    login = document.getElementById("log1").value;
    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        let r = responseJSON.RESULTS;

        if (r[0].Error){
            alert(r[0].Error)
        } else {
            token = r[0].player_token[0]
            console.log(r)
            start.classList.add("hide");
            roomList.classList.remove("hide");
            displayRooms()
        }
    });
}

function register() {
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();

    fd.append("pname", "Registration");
    fd.append("db", "265117");
    fd.append("p1", document.getElementById("log2").value);
    fd.append("p2", document.getElementById("pas2").value);
    login = document.getElementById("log2").value;

    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {

        let r = responseJSON.RESULTS;
        token = r[0].player_token[0]
        if (r[0].Error){
            alert(r[0].Error)
        } else {
            start.classList.add("hide");
            roomList.classList.remove("hide");
        }
    });
}

function displayRooms(){
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append('pname', 'AllRooms');
    fd.append('db', '265117');
    fd.append('format', 'columns_compact');
    const interval = setInterval(function() {
        if (showRoom){
            fetch(url, {
                method: "POST",
                body: fd
            }).then((response) => {
                if (response.ok){
                    return response.json()
                }
                else {
                    return show_error('ошибка сети)');
                }
            }).then((responseJSON) => {
                let r = responseJSON.RESULTS;
                console.log(r)
                if (r[0].Error){
                    alert(r[0].Error)
                }
                else {
                    let v = document.getElementsByClassName('all-rooms')[0];
                    v.innerHTML = ' ';
                    for (let i = 0; i < r[0].ID_Room.length; i++){
                        v.innerHTML +=
                            "<div>" +
                            "ID комнаты: "+r[0].ID_Room[i] + " | Количество мест: " + r[0].MaxSeats[i] + " | игроков сейчас: " + r[0].count_players[i] +
                            "</div>";
                    }
                }
            });
        }
        else clearInterval(interval);
    }, 3000);
}

function openNewRoom(){
    document.getElementsByClassName('par-new-room')[0].classList.remove('hide');
    document.getElementsByClassName('all-rooms')[0].classList.add('hide');
    document.getElementsByClassName('my-rooms')[0].classList.add('hide');
    document.getElementsByClassName('cr-room')[0].classList.add('hide');
    document.getElementById('btnCmb').classList.add('hide')
    document.getElementById('connectRoom').classList.add('hide')
    showRoom = false;
}

function backToReg(){
    start.classList.remove("hide");
    roomList.classList.add("hide");
}

function backToRooms(){
    document.getElementsByClassName('par-new-room')[0].classList.add('hide');
    document.getElementsByClassName('all-rooms')[0].classList.remove('hide');
    document.getElementsByClassName('my-rooms')[0].classList.remove('hide');
    document.getElementsByClassName('cr-room')[0].classList.remove('hide');
    document.getElementById('btnCmb').classList.remove('hide')
    document.getElementById('connectRoom').classList.remove('hide')
    showRoom = true;
    displayRooms()
}

function newRoom() {
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append("pname", "CreateRoom");
    fd.append("db", "265117");
    fd.append("p1", token);
    fd.append("p2", document.getElementById("count-player").value);
    fd.append("p3", document.getElementById("time-move").value);

    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return ("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
        room_id = responseJSON.RESULTS[0].ID[0];
        displayWaitingRoom()
    });
}

function enterRoom() {
    let q = document.getElementById("roomIdInput").value;
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append("pname", "EntranceRoom");
    fd.append("db", "265117");
    fd.append("p1", token);
    fd.append("p2", q);
    room_id = q;
    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
        if (responseJSON.RESULTS[6]){
            document.getElementsByClassName('par-new-room')[0].classList.add('hide');
            document.getElementsByClassName('all-rooms')[0].classList.add('hide');
            document.getElementsByClassName('my-rooms')[0].classList.add('hide');
            document.getElementsByClassName('cr-room')[0].classList.add('hide');
            document.getElementById('btnCmb').classList.add('hide');
            document.getElementById('connectRoom').classList.add('hide');
            document.getElementsByClassName('stayAtroom')[0].classList.add('hide')
            for (let i = 0; i < responseJSON.RESULTS[0].ID_Player.length; i++){
                if (responseJSON.RESULTS[0].Login[i] === login){
                    player_id = responseJSON.RESULTS[0].ID_Player[i];
                }
            }
            showRoom = false;
            inWaitingRoom = false;
            document.getElementsByClassName('game')[0].classList.remove('hide')

            gameState()
        } else {
            displayWaitingRoom()
        }
    });
}

function displayWaitingRoom(){
    document.getElementsByClassName('par-new-room')[0].classList.add('hide');
    document.getElementsByClassName('all-rooms')[0].classList.add('hide');
    document.getElementsByClassName('my-rooms')[0].classList.add('hide');
    document.getElementsByClassName('cr-room')[0].classList.add('hide');
    document.getElementById('btnCmb').classList.add('hide');
    document.getElementById('connectRoom').classList.add('hide');
    document.getElementsByClassName('stayAtroom')[0].classList.remove('hide')
    showRoom = false;
    inWaitingRoom = true;

    roomState()
}

function roomState(){
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append('pname', 'StayAtRoom');
    fd.append('db', '265117');
    fd.append('p1', token);
    fd.append('p2', room_id);
    fd.append('format', 'columns_compact');
    const interval = setInterval(function() {
        if (inWaitingRoom){
            fetch(url, {
                method: "POST",
                body: fd
            }).then((response) => {
                if (response.ok){
                    return response.json()
                }
                else {
                    return show_error('ошибка сети)');
                }
            }).then((responseJSON) => {
                console.log('imhere')
                console.log(responseJSON)
                let r = responseJSON.RESULTS;
                console.log(r)
                console.log(r.length)
                if (r[0].Error){
                    alert(r[0].Error)
                    clearInterval(interval)
                    document.getElementsByClassName('stayAtroom')[0].classList.add('hide')
                    backToRooms()
                }
                else {
                    if (r.length >2) {
                        player_id = responseJSON.RESULTS[0].ID_Player[0];
                        showRoom = false;
                        inWaitingRoom = false;
                        clearInterval(interval)
                        document.getElementsByClassName('stayAtroom')[0].classList.add('hide')
                        document.getElementsByClassName('game')[0].classList.remove('hide')
                        gameState()
                    }
                    let v = document.getElementsByClassName('listPlayers')[0];
                    v.innerHTML = ' ';
                    for (let i = 0; i < r[0].ID_Player.length; i++){
                        v.innerHTML +=
                            "<div>" +
                            "ID игрока: "+r[0].ID_Player[i] + " | Логин игрока " + r[0].Login[i] + " | место на поле " + r[0].SeatNumber[i] +
                            "</div>";
                    }
                }
            });
        }
        else clearInterval(interval);
    }, 3000);
}

function gameState(){
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append('pname', 'GameState');
    fd.append('db', '265117');
    fd.append('p1', token);
    fd.append('p2', player_id);
    fd.append('p3', room_id);
    fd.append('format', 'columns_compact');
    const interval = setInterval(function() {
        fetch(url, {
            method: "POST",
            body: fd
        }).then((response) => {
            if (response.ok){
                return response.json()
            }
            else {
                return show_error('ошибка сети)');
            }
        }).then((responseJSON) => {
            console.log(responseJSON)
            let r = responseJSON.RESULTS;
            
            if (r[0].Error){
            alert(r[0].Error[0])
            return;
        }

            seconds = 0;
            clearInterval(timerQ);

            players = [];
            for (let i = 0; i < r[0].ID_Player.length; i++){
                if (+r[0].ID_Player[i] === +player_id){
                    players.push([r[0].ID_Player[i],0])
                }
                players.push([r[0].ID_Player[i],r[0].SeatNumber[i]])
            }

            players = players.sort((a, b) => a[1] - b[1]);
            for (let i = 0; i < r[0].ID_Player.length; i++){
                players[i][1] = i  + 1;
            }

            let targetDiv = document.getElementById('my-cards');
            targetDiv.innerHTML = ' '
            cards = []
            monsters = []

            timerQ = setInterval(function () {
                let secs = +r[1].Deadline[0] - seconds;
                document.getElementById('count-time').innerHTML =
                    ` Ходит: ${r[1].Login[0]}, 
                    осталось действий:  ${r[1].RemainingSteps[0]},
                    осталось времени: ${(secs < 10 ? ('0' + secs): secs)}`;

                seconds += 1
            }, 1000);

            if (r[1].Login[0] !== login){
                console.log('notMyTurn')
                let g = document.getElementById('give');
                let c = document.getElementById('chooseDisc');
                let p = document.getElementById('put')
                if (!g.classList.contains('hide')){
                    g.classList.add('hide')
                }
                if (!c.classList.contains('hide')){
                    c.classList.add('hide')
                }
                if (!p.classList.contains('hide')){
                    p.classList.add('hide')
                }
            }
            else{
                console.log('myTurn')
                let g = document.getElementById('give');
                let c = document.getElementById('chooseDisc');
                let p = document.getElementById('put')
                if (g.classList.contains('hide')){
                    g.classList.remove('hide')
                }
                if (c.classList.contains('hide')){
                    c.classList.remove('hide')
                }
                if (p.classList.contains('hide')){
                    p.classList.remove('hide')
                }
            }

            for (let i = 0; i < r[5].ID.length; i++){
                cards.push([r[5].ID[i],r[5].PartName[i],r[5].ID_Card[i]])
            }

            for (let i = 0; i < r[4].ID_Monster.length; i++){
                monsters.push(r[4].ID_Monster[i])
            }

            if (!placeCardChoosing && !placeCardChoosing2){
                for (let i = 0; i < r[5].ID.length; i++){
                    targetDiv.innerHTML +=
                        `<div class="crd">
                        <p>${r[5].ID_Card[i]}</p>
                        <img src="cards/${r[5].ID[i]}.png">
                    </div>`;
                }
            }else {
                if (placeCardChoosing){
                    for (let i = 0; i < r[5].ID.length; i++){
                        targetDiv.innerHTML +=
                            `<div class="crd ${chosenCards.includes(r[5].ID_Card[i].toString()) ? 'chosen' : 'choosing'}">
                        <p>${r[5].ID_Card[i]}</p>
                        <img src="cards/${r[5].ID[i]}.png">
                    </div>`;
                    }
                    let d = document.getElementsByClassName('crd');

                    for (let e of d) {
                        e.addEventListener('click', function (){
                            if (!e.classList.contains('chosen')){
                                chosenCards.push(e.getElementsByTagName("p")[0].innerText)
                                e.classList.remove('choosing')
                                e.classList.add('chosen')
                                placeCardChosen = true;
                            }
                        })
                    }
                }
                else {
                    for (let i = 0; i < r[5].ID.length; i++){
                        targetDiv.innerHTML +=
                            `<div class="crd choosing">
                        <p>${r[5].ID_Card[i]}</p>
                        <img src="cards/${r[5].ID[i]}.png">
                    </div>`;
                    }

                    let d = document.getElementsByClassName('crd');

                    for (let e of d) {
                        e.addEventListener('click', function (){
                            if (!e.classList.contains('chosen')){
                                chosenCard2 = e.getElementsByTagName("p")[0].innerText
                                for (let e of d) {
                                    if (e.classList.contains('chosen')) e.classList.remove('chosen')
                                    if (e.classList.contains('choosing')) e.classList.remove('choosing')
                                }
                                placeCardChosen2 = true;
                                PlayCard();
                            }
                        })
                    }
                }
            }


            for (let i = 0; i < 5; i ++){
                for (let j = 1; j < 4; j ++){
                    let d = document.getElementsByClassName('mcards' + i.toString() + j.toString());
                    for (let e of d){
                        if (!e.classList.contains('filled')){
                            e.classList.remove('filled')
                        }
                        e.innerHTML = '';
                    }
                }
            }

            let prevMonster;
            let mId;
            let prevField;
            for (let i = 0; i < r[3].ID_Player.length; i++){
                let fieldNumber;

                for (let e of players){
                    if (+e[0] === +r[3].ID_Player[i]){
                        fieldNumber = e[1];
                            if (prevField !== fieldNumber && prevField !== undefined){
                            mId -= `1`;
                        }
                        prevField = fieldNumber;
                        break;
                    }
                }

                let bodyPart;


                if (+r[3].ID_Player === +player_id){
                    for (let j = 0; j < monsters.length; j++){
                        if (+monsters[j] === +r[3].ID_Monster[i]){
                            mId = j;
                        }
                    }
                }
                else {
                    if (prevMonster === undefined){
                        mId = 0;
                    } else {
                        if (+prevMonster !== +r[3].ID_Monster[i]){
                            mId += 1
                        }
                    }
                    prevMonster = +r[3].ID_Monster[i];
                }


                if (mId === undefined) continue;

                switch (r[3].NameBodyPart[i]) {
                    case 'Голова':
                        bodyPart = 1
                        break;
                    case 'Туловище':
                        bodyPart = 2
                        break;
                    case 'Ноги':
                        bodyPart = 3
                        break;
                }

                let d = document.getElementsByClassName('mcards' + mId.toString() + bodyPart.toString());
                let divv = d[0];
                for (let e of d){
                    if (e.classList.contains(`pl${fieldNumber}`)){
                        divv = e;
                    }
                }
                divv.classList.add('filled')
                divv.innerHTML +=
                    `<img src="${"cards/" + r[3].ID[i] + '.png'}" style="width: 80px; height: 52.400px">`

            }

        });
    }, 3000);
}

function openCards(){
    let targetDiv = document.getElementById('my-cards');
    targetDiv.classList.contains('hide') ? targetDiv.classList.remove('hide') : targetDiv.classList.add('hide')
}

function PutCard(){
    if (!cardChoosing && chosenCard === -1){
        cardChoosing = true;
        for (let q of document.getElementsByClassName('card')){
                if (!q.classList.contains('filled') && q.classList.contains('pl1'))
                q.style.border = '2px solid green';
        }
    } else if (cardChoosing && chosenCard === -1){
        for (let q of document.getElementsByClassName('card')){
            q.style.border = '1px dotted purple';
        }
        cardChoosing = false;
    }
}

function cardPut(){
    for (let q of document.getElementsByClassName('card')){
        q.style.border = '1px dotted purple';
    }
    PlayCard()
}

function chooseCards2 (){
    if (placeCardChoosing2){
        document.getElementById('discard2').classList.remove('hide');
        let d = document.getElementsByClassName('crd');
        for (let e of d) {
            e.classList.add('choosing')
        }
        for (let e of d) {
            e.addEventListener('click', function (){
                if (!e.classList.contains('chosen')){
                    chosenCard2 = e.getElementsByTagName("p")[0].innerText
                    for (let e of d) {
                        if (e.classList.contains('chosen')) e.classList.remove('chosen')
                        if (e.classList.contains('choosing')) e.classList.remove('choosing')
                    }
                    placeCardChosen2 = true;
                    PlayCard();
                }
            })
        }
    }
}

function cancel2(){
    placeCardChoosing2 = false;
    placeCardChosen2 = false;
    chosenCard2 = -1;
    document.getElementById('discard2').classList.add('hide');
    let d = document.getElementsByClassName('crd');
    for (let e of d) {
        if (e.classList.contains('chosen')) e.classList.remove('chosen')
        if (e.classList.contains('choosing')) e.classList.remove('choosing')
    }
}

function PlayCard(){
    if (!placeCardChosen2){
        placeCardChoosing2 = true;
        chooseCards2()
        return;
    }
    console.log('here')

    let cardNumber = chosenCard2;
    let ifInCards = false;
    for (let e of cards){
        if (e[2] == cardNumber){
            ifInCards = true;
        }
    }

    if (!ifInCards) {
        alert('у вас нет такой карты');
        chosenCard = -1;
        return;
    }

    let monster = chosenCard.charAt(0);
    let bodyPart = chosenCard.charAt(1);

    switch (bodyPart) {
        case '1':
            bodyPart = 'Голова'
            break;
        case '2':
            bodyPart = 'Туловище'
            break;
        case '3':
            bodyPart = 'Ноги'
            break;
    }

    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append("pname", "PlayCard");
    fd.append("db", "265117");
    fd.append("p1", token);
    fd.append("p2", player_id);
    fd.append("p3", room_id);
    fd.append('p4', cardNumber);
    fd.append('p5', monsters[monster]);
    fd.append('p6', bodyPart);

    console.log(
        token + " " +
        player_id + " " +
        room_id + " " +
        cardNumber + " " +
        monsters[monster] + " " +
        bodyPart + " "
    )

    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
        chosenCard = -1;
        chosenCard2 = -1;
        placeCardChoosing2 = false;
        placeCardChosen2 = false;
        document.getElementById('discard2').classList.add('hide');
    });
}

function takeCard(){
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append("pname", "TakeCard");
    fd.append("db", "265117");
    fd.append("p1", token);
    fd.append("p2", player_id);
    fd.append("p3", room_id);

    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
    });
}

function chooseCards (){
    if (placeCardChoosing){
        document.getElementById('discard').classList.remove('hide');
        let d = document.getElementsByClassName('crd');
        for (let e of d) {
            e.classList.add('choosing')
        }
        for (let e of d) {
            e.addEventListener('click', function (){
                if (!e.classList.contains('chosen')){
                    chosenCards.push(e.getElementsByTagName("p")[0].innerText)
                    e.classList.remove('choosing')
                    e.classList.add('chosen')
                    placeCardChosen = true;
                }
            })
        }
    }
}

function cancel(){
    placeCardChoosing = false;
    placeCardChosen = false;
    chosenCards = [];
    document.getElementById('discard').classList.add('hide');
    let d = document.getElementsByClassName('crd');
    for (let e of d) {
        if (e.classList.contains('chosen')) e.classList.remove('chosen')
        if (e.classList.contains('choosing')) e.classList.remove('choosing')
    }
}

function discardCards(){
    if (!placeCardChosen){
        placeCardChoosing = true;
        chooseCards()
        return;
    }

    for (let e of chosenCards){
        const url = "https://sql.lavro.ru/call.php?";
        let fd = new FormData();
        fd.append("pname", "ChooseDiscardedCard");
        fd.append("db", "265117");
        fd.append("p1", token);
        fd.append("p2", player_id);
        fd.append("p3", e);
        fetch(url, {
            method: "POST",
            body: fd
        }).then((response) => {
            if(response.ok){
                return response.json()
            }
            else{
                return error("Ошибка");
            }
        }).then((responseJSON) => {
            console.log(responseJSON)
        });
    }

    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();
    fd.append("pname", "DiscardAndTakeCard");
    fd.append("db", "265117");
    fd.append("p1", token);
    fd.append("p2", player_id);
    fd.append("p3", room_id);
    fetch(url, {
        method: "POST",
        body: fd
    }).then((response) => {
        if(response.ok){
            return response.json()
        }
        else{
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
    });

    chosenCards = [];
    placeCardChoosing = false;
    placeCardChosen = false;
    document.getElementById('discard').classList.remove('hide');
}