// Loader für alle 118 Elementgeschichten. Die bisher fachlich freigegebenen Texte bleiben unverändert.
(function(){
  "use strict";
  var v="20260916-3";
  var files=[
    "elementgeschichten_freigegeben.js",
    "elementgeschichten_1_30_missing.js",
    "elementgeschichten_31_52.js",
    "elementgeschichten_53_74.js",
    "elementgeschichten_75_96.js",
    "elementgeschichten_97_118.js"
  ];
  for(var i=0;i<files.length;i++){
    document.write('<script src="'+files[i]+'?v='+v+'"><\/script>');
  }
})();

// Passwort vergessen / Passwort zurücksetzen.
// Dieser Zusatz hängt sich nur an die bestehende Supabase-Anmeldung an und verändert das Spiel nicht.
(function(){
  "use strict";

  var recoveryRequested=/(?:^|[?#&])type=recovery(?:&|$)/i.test(location.hash+"&"+location.search);
  var recoveryMode=false;

  function byId(id){ return document.getElementById(id); }

  function showAuthMessage(text,kind){
    var box=byId("authMsg");
    if(!box) return;
    box.textContent=text;
    box.className="notice "+(kind||"");
  }

  function showRecoveryMessage(text,kind){
    var box=byId("passwordRecoveryMsg");
    if(!box) return;
    box.textContent=text;
    box.className="notice "+(kind||"");
  }

  function hideOtherCards(){
    ["lobbyCard","gameCard","resultCard","leaderCard","statsCard"].forEach(function(id){
      var el=byId(id);
      if(el) el.classList.add("hidden");
    });
  }

  function showRecoveryPanel(){
    var authCard=byId("authCard");
    var grid=authCard && authCard.querySelector(".auth-grid");
    var guest=authCard && authCard.querySelector(".guest-entry");
    var panel=byId("passwordRecoveryPanel");
    if(!authCard || !panel) return;
    recoveryMode=true;
    authCard.classList.remove("hidden");
    if(grid) grid.classList.add("hidden");
    if(guest) guest.classList.add("hidden");
    panel.classList.remove("hidden");
    hideOtherCards();
    setTimeout(function(){ panel.scrollIntoView({behavior:"smooth",block:"center"}); },0);
  }

  function leaveRecoveryPanel(){
    var authCard=byId("authCard");
    var grid=authCard && authCard.querySelector(".auth-grid");
    var guest=authCard && authCard.querySelector(".guest-entry");
    var panel=byId("passwordRecoveryPanel");
    recoveryMode=false;
    if(panel) panel.classList.add("hidden");
    if(grid) grid.classList.remove("hidden");
    if(guest) guest.classList.remove("hidden");
  }

  function cleanRecoveryUrl(){
    try{
      history.replaceState(null,document.title,location.pathname);
    }catch(_e){}
  }

  function installRecoveryUi(){
    var authCard=byId("authCard");
    if(!authCard || byId("forgotPasswordBtn")) return;

    var loginBox=authCard.querySelector(".auth-grid > div");
    var loginButton=loginBox && loginBox.querySelector("button.primary");
    if(loginButton){
      var forgot=document.createElement("button");
      forgot.id="forgotPasswordBtn";
      forgot.type="button";
      forgot.className="secondary";
      forgot.style.marginTop="12px";
      forgot.style.marginLeft="8px";
      forgot.textContent="Passwort vergessen?";
      loginButton.insertAdjacentElement("afterend",forgot);

      forgot.addEventListener("click",async function(){
        var email=(byId("loginEmail") && byId("loginEmail").value || "").trim();
        if(!email){
          showAuthMessage("Bitte zuerst deine E-Mail-Adresse eingeben.","bad");
          return;
        }
        if(typeof supabaseClient==="undefined"){
          showAuthMessage("Passwort-Zurücksetzen ist gerade nicht verfügbar. Bitte die Seite neu laden.","bad");
          return;
        }
        forgot.disabled=true;
        var redirectTo=location.origin+location.pathname;
        var result=await supabaseClient.auth.resetPasswordForEmail(email,{redirectTo:redirectTo});
        forgot.disabled=false;
        if(result.error){
          showAuthMessage("Passwort-Link konnte nicht gesendet werden: "+result.error.message,"bad");
          return;
        }
        showAuthMessage("Wenn zu dieser E-Mail-Adresse ein Konto existiert, wurde ein Link zum Festlegen eines neuen Passworts gesendet. Bitte auch den Spam-Ordner prüfen.","good");
      });
    }

    var panel=document.createElement("div");
    panel.id="passwordRecoveryPanel";
    panel.className="hidden";
    panel.style.maxWidth="560px";
    panel.style.margin="0 auto";
    panel.innerHTML='\
      <h2>Neues Passwort festlegen</h2>\
      <p class="small">Gib zweimal dein neues Passwort ein. Danach kannst du das Elementenpuzzle wieder mit diesem Konto benutzen.</p>\
      <label for="newPassword">Neues Passwort</label>\
      <input id="newPassword" type="password" minlength="6" autocomplete="new-password">\
      <label for="newPasswordRepeat">Passwort wiederholen</label>\
      <input id="newPasswordRepeat" type="password" minlength="6" autocomplete="new-password">\
      <div class="actions"><button id="saveNewPasswordBtn" class="primary" type="button">Neues Passwort speichern</button></div>\
      <div id="passwordRecoveryMsg" class="notice hidden"></div>';

    var guestEntry=authCard.querySelector(".guest-entry");
    if(guestEntry) authCard.insertBefore(panel,guestEntry);
    else authCard.appendChild(panel);

    byId("saveNewPasswordBtn").addEventListener("click",async function(){
      var first=(byId("newPassword") && byId("newPassword").value)||"";
      var second=(byId("newPasswordRepeat") && byId("newPasswordRepeat").value)||"";
      if(first.length<6){
        showRecoveryMessage("Das neue Passwort muss mindestens 6 Zeichen lang sein.","bad");
        return;
      }
      if(first!==second){
        showRecoveryMessage("Die beiden Passwörter stimmen nicht überein.","bad");
        return;
      }
      if(typeof supabaseClient==="undefined"){
        showRecoveryMessage("Die Anmeldung ist noch nicht bereit. Bitte die Seite neu laden.","bad");
        return;
      }
      var button=byId("saveNewPasswordBtn");
      button.disabled=true;
      var result=await supabaseClient.auth.updateUser({password:first});
      button.disabled=false;
      if(result.error){
        showRecoveryMessage("Das Passwort konnte nicht geändert werden: "+result.error.message,"bad");
        return;
      }
      recoveryMode=false;
      cleanRecoveryUrl();
      leaveRecoveryPanel();
      alert("Das Passwort wurde geändert. Du bist jetzt angemeldet.");
      if(typeof renderAuth==="function") renderAuth();
    });
  }

  installRecoveryUi();

  window.addEventListener("load",function(){
    installRecoveryUi();
    if(recoveryRequested) showRecoveryPanel();
    if(typeof supabaseClient!=="undefined"){
      supabaseClient.auth.onAuthStateChange(function(event){
        if(event==="PASSWORD_RECOVERY"){
          recoveryRequested=true;
          setTimeout(showRecoveryPanel,0);
        }else if(recoveryMode && event!=="USER_UPDATED"){
          setTimeout(showRecoveryPanel,0);
        }
      });
    }
  });
})();

// Dauerhaft erreichbare Abmeldung – auch während eines laufenden oder gelösten Rätsels.
(function(){
  "use strict";

  function ensureLogoutButton(){
    if(document.getElementById("globalLogoutBtn")) return document.getElementById("globalLogoutBtn");
    var button=document.createElement("button");
    button.id="globalLogoutBtn";
    button.type="button";
    button.className="secondary";
    button.style.position="fixed";
    button.style.top="14px";
    button.style.right="14px";
    button.style.zIndex="10000";
    button.style.padding="10px 14px";
    button.style.boxShadow="0 6px 22px rgba(0,0,0,.28)";
    button.style.display="none";
    button.addEventListener("click",async function(){
      button.disabled=true;
      try{
        if(typeof logout==="function"){
          await logout();
        }else if(typeof supabaseClient!=="undefined"){
          await supabaseClient.auth.signOut();
          location.reload();
        }
      }finally{
        button.disabled=false;
      }
    });
    document.body.appendChild(button);
    return button;
  }

  function updateLogoutButton(currentSession){
    var button=ensureLogoutButton();
    if(!currentSession){
      button.style.display="none";
      return;
    }
    var name=currentSession.user && currentSession.user.user_metadata && currentSession.user.user_metadata.username;
    button.textContent=name ? "Abmelden – "+name : "Abmelden";
    button.style.display="block";
  }

  window.addEventListener("load",async function(){
    if(typeof supabaseClient==="undefined") return;
    var result=await supabaseClient.auth.getSession();
    updateLogoutButton(result.data && result.data.session);
    supabaseClient.auth.onAuthStateChange(function(_event,newSession){
      updateLogoutButton(newSession);
    });
  });
})();
