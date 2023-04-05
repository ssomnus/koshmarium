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

let showRoom = true;
let token;

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
                    v.innerHTML += '<br><br>'
                    v = document.getElementsByClassName('my-rooms')[0];
                    v.innerHTML = ' ';
                    let prev = r[1].ID_Room[0];
                    for (let i = 0; i < r[1].ID_Room.length; i++){
                        if (r[1].ID_Room[i] !== prev) v.innerHTML += '<br>';
                        v.innerHTML +=
                            "ID комнаты: " + r[1].ID_Room[i] +
                            "| Login: " + r[1].Login[i] +
                            " Номер места: " + r[1].SeatNumber[i] +
                            "<br>"
                        prev = r[1].ID_Room[i];
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
    showRoom = false;
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
            return error("Ошибка");
        }
    }).then((responseJSON) => {
        console.log(responseJSON)
    });
}