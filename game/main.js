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

let inWaitingRoom = false;
let showRoom = true;
let token;
let room_id;
let player_id;

function signin() {
    const url = "https://sql.lavro.ru/call.php?";
    let fd = new FormData();

    fd.append("pname", "SignIn");
    fd.append("db", "265117");
    fd.append("p1", document.getElementById("log1").value);
    fd.append("p2", document.getElementById("pas1").value);

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

        if (responseJSON.RESULTS[6]){
            document.getElementsByClassName('par-new-room')[0].classList.add('hide');
            document.getElementsByClassName('all-rooms')[0].classList.add('hide');
            document.getElementsByClassName('my-rooms')[0].classList.add('hide');
            document.getElementsByClassName('cr-room')[0].classList.add('hide');
            document.getElementById('btnCmb').classList.add('hide');
            document.getElementById('connectRoom').classList.add('hide');
            document.getElementsByClassName('stayAtroom')[0].classList.add('hide')
            player_id = responseJSON.RESULTS[0].ID_Player[0];
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
    fd.append('p1', player_id);
    fd.append('p2', room_id);
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
        });

    }, 3000);
}