function register() {
    const url = "https://sql.lavro.ru/call.php?";
    let form = new FormData(document.getElementById(""));
    let fd = new FormData();

    fd.append("pname", "Registration");
    fd.append("db", "265117");
    fd.append("log1", form.get("Login"));
    fd.append("pas1", form.get("Password"));

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