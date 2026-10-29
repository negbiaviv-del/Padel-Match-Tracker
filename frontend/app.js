// מונע שחזור של גלילה ישנה כאשר הדף חוזר מזיכרון הדפדפן.
if ("scrollRestoration" in history) {
  history.scrollRestoration = "manual";
}

window.addEventListener("pageshow", (event) => {
  if (event.persisted) {
    window.location.reload();
    return;
  }

  window.scrollTo(0, 0);
});

// מגדיר את הנתיב היחסי לקריאה, שמירה ומחיקה של משחקים.
const matchesApiPath = "/api/v1/matches";

// מאתר את רכיבי העמוד שדורשים עדכון.
const elements = {
  connectionStatus: document.getElementById("connection-status"),
  connectionText: document.querySelector("[data-connection-text]"),
  heroMatchCount: document.getElementById("hero-match-count"),
  heroLatestResult: document.getElementById("hero-latest-result"),
  totalMatches: document.getElementById("total-matches"),
  matchesList: document.getElementById("matches-list"),
  matchCardTemplate: document.getElementById("match-card-template"),
  refreshButton: document.getElementById("refresh-matches"),
  matchForm: document.getElementById("match-form"),
  playedAt: document.getElementById("played-at"),
  notes: document.getElementById("notes"),
  notesCounter: document.getElementById("notes-counter"),
  formError: document.getElementById("form-error"),
  formHelp: document.getElementById("form-help"),
  saveButton: document.querySelector(".primary-button"),
  saveButtonText: document.querySelector(".primary-button span"),
  toast: document.getElementById("toast"),
  toastMessage: document.getElementById("toast-message"),
  deleteDialog: document.getElementById("delete-dialog"),
  deleteDialogMessage: document.getElementById("delete-dialog-message"),
  deleteDialogError: document.getElementById("delete-dialog-error"),
  cancelDeleteButton: document.getElementById("cancel-delete"),
  confirmDeleteButton: document.getElementById("confirm-delete"),
};

// שומר מזהה של הודעת ההצלחה הזמנית.
let toastTimer;

// שומר זמנית את מזהה המשחק שממתין לאישור מחיקה.
let pendingDeletionMatchId = null;

// מעדכן את מצב החיבור שמוצג למשתמש.
function setConnectionStatus(message, isConnected) {
  elements.connectionText.textContent = message;
  elements.connectionStatus.dataset.status = isConnected ? "online" : "offline";
}

// מציג מצב טעינה בזמן שמחכים לתשובה מהשירות.
function renderLoading() {
  const loadingState = document.createElement("div");
  const loadingText = document.createElement("p");

  loadingState.className = "loading-state";
  loadingText.textContent = "Loading your match history...";
  loadingState.append(loadingText);

  elements.matchesList.replaceChildren(loadingState);
  elements.matchesList.setAttribute("aria-busy", "true");
}

// מציג מצב ריק כאשר אין משחקים.
function renderEmptyState() {
  const emptyState = document.createElement("div");
  const emptyText = document.createElement("p");

  emptyState.className = "empty-state";
  emptyText.textContent = "No matches have been recorded yet.";
  emptyState.append(emptyText);

  elements.matchesList.replaceChildren(emptyState);
  elements.matchesList.setAttribute("aria-busy", "false");
}

// מציג הודעה כאשר קריאת המשחקים נכשלת.
function renderHistoryError() {
  const errorState = document.createElement("div");
  const errorText = document.createElement("p");

  errorState.className = "empty-state";
  errorText.textContent = "We could not load the match history. Please try again.";
  errorState.append(errorText);

  elements.matchesList.replaceChildren(errorState);
  elements.matchesList.setAttribute("aria-busy", "false");
}

// ממיר זמן מהשירות לתאריך קריא.
function formatMatchDate(value) {
  return new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  }).format(new Date(value));
}

// ממיר זמן מהשירות לשעה קריאה.
function formatMatchTime(value) {
  return new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

// יוצר תיאור קצר של תוצאת המשחק האחרון.
function formatLatestResult(match) {
  const winningTeam = match.winner === "team_a" ? "Team A" : "Team B";

  return `${winningTeam} won ${match.team_a_sets}:${match.team_b_sets}`;
}

// יוצר כרטיס משחק, ממלא אותו בנתונים ומכין פעולת מחיקה.
function createMatchCard(match) {
  const cardFragment = elements.matchCardTemplate.content.cloneNode(true);
  const notes = cardFragment.querySelector("[data-match-notes]");
  const teamARow = cardFragment.querySelector("[data-team-a-row]");
  const teamBRow = cardFragment.querySelector("[data-team-b-row]");
  const deleteButton = cardFragment.querySelector("[data-delete-match]");

  cardFragment.querySelector("[data-match-date]").textContent = formatMatchDate(
    match.played_at,
  );
  cardFragment.querySelector("[data-match-time]").textContent = formatMatchTime(
    match.played_at,
  );
  cardFragment.querySelector("[data-match-winner]").textContent =
    match.winner === "team_a" ? "Team A won" : "Team B won";
  cardFragment.querySelector("[data-team-a-players]").textContent =
    match.team_a.join(" & ");
  cardFragment.querySelector("[data-team-b-players]").textContent =
    match.team_b.join(" & ");
  cardFragment.querySelector("[data-team-a-score]").textContent =
    match.team_a_sets;
  cardFragment.querySelector("[data-team-b-score]").textContent =
    match.team_b_sets;

  if (match.winner === "team_a") {
    teamARow.classList.add("is-winner");
  } else {
    teamBRow.classList.add("is-winner");
  }

  if (match.notes) {
    notes.textContent = match.notes;
    notes.hidden = false;
  }

  if (deleteButton instanceof HTMLButtonElement) {
    const matchDescription =
      `${match.team_a.join(" & ")} versus ${match.team_b.join(" & ")}`;

    deleteButton.dataset.matchId = match.id;
    deleteButton.dataset.matchDescription = matchDescription;
    deleteButton.setAttribute(
      "aria-label",
      `Delete match: ${matchDescription}`,
    );
  }

  return cardFragment;
}

// מציג משחקים ונתוני סיכום בממשק.
function renderMatches(matches) {
  elements.heroMatchCount.textContent = String(matches.length);
  elements.totalMatches.textContent = String(matches.length);
  elements.matchesList.replaceChildren();
  elements.matchesList.setAttribute("aria-busy", "false");

  if (matches.length === 0) {
    elements.heroLatestResult.textContent = "No matches yet";
    renderEmptyState();
    return;
  }

  elements.heroLatestResult.textContent = formatLatestResult(matches[0]);

  for (const match of matches) {
    elements.matchesList.append(createMatchCard(match));
  }
}

// קורא משחקים מהשירות ומעדכן את הממשק.
async function loadMatches() {
  renderLoading();
  setConnectionStatus("Checking connection", false);
  elements.refreshButton.disabled = true;

  try {
    const response = await fetch(matchesApiPath);

    if (!response.ok) {
      throw new Error("Unable to load matches");
    }

    const matches = await response.json();

    renderMatches(matches);
    setConnectionStatus("Connected", true);
  } catch (error) {
    console.error(error);
    renderHistoryError();
    setConnectionStatus("Connection unavailable", false);
  } finally {
    elements.refreshButton.disabled = false;
  }
}

// מציג הודעת שגיאה וגולל אליה.
function showFormError(message) {
  elements.formError.textContent = message;
  elements.formError.hidden = false;

  window.requestAnimationFrame(() => {
    elements.formError.scrollIntoView({
      behavior: "smooth",
      block: "center",
    });
  });
}

// מסתיר הודעת שגיאה קודמת.
function clearFormError() {
  elements.formError.textContent = "";
  elements.formError.hidden = true;
}

// מחזיר את הודעת העזר למצבה הרגיל.
function resetFormHelp() {
  elements.formHelp.textContent = "Results are checked before they are saved.";
  elements.formHelp.classList.remove("form-help--success");
}

// מציג הודעת הצלחה ליד כפתור השמירה.
function showFormSuccess(message) {
  elements.formHelp.textContent = message;
  elements.formHelp.classList.add("form-help--success");
}

// מציג הודעת הצלחה קצרה.
function showToast(message) {
  window.clearTimeout(toastTimer);

  elements.toastMessage.textContent = message;
  elements.toast.hidden = false;

  toastTimer = window.setTimeout(() => {
    elements.toast.hidden = true;
  }, 4000);
}

// מעדכן את מונה התווים בשדה ההערות.
function updateNotesCounter() {
  elements.notesCounter.textContent = `${elements.notes.value.length} / 500`;
}

// משנה את מצב כפתור השמירה בזמן שליחה.
function setSavingState(isSaving) {
  elements.saveButton.disabled = isSaving;
  elements.saveButtonText.textContent = isSaving ? "Saving..." : "Save match";
}

// בונה מידע תקין לשליחה מתוך שדות הטופס.
function buildMatchPayload() {
  const formData = new FormData(elements.matchForm);
  const playedAtValue = String(formData.get("played_at") || "");
  const playedAt = new Date(playedAtValue);

  if (Number.isNaN(playedAt.getTime())) {
    throw new Error("Please choose a valid match date and time.");
  }

  const notes = String(formData.get("notes") || "").trim();

  return {
    played_at: playedAt.toISOString(),
    team_a: [
      String(formData.get("team_a_player_1") || "").trim(),
      String(formData.get("team_a_player_2") || "").trim(),
    ],
    team_b: [
      String(formData.get("team_b_player_1") || "").trim(),
      String(formData.get("team_b_player_2") || "").trim(),
    ],
    team_a_sets: Number(formData.get("team_a_sets")),
    team_b_sets: Number(formData.get("team_b_sets")),
    notes: notes || null,
  };
}

// מחלץ הודעת שגיאה ברורה מתשובת השירות.
function getErrorMessage(payload) {
  const fields = payload?.error?.fields;

  if (Array.isArray(fields) && fields.length > 0) {
    return fields
      .map((field) => `${field.field}: ${field.message}`)
      .join(" ");
  }

  return (
    payload?.error?.message ||
    payload?.detail ||
    "We could not complete the request. Please try again."
  );
}

// קורא תשובה בפורמט נתונים בלי להפיל את הממשק בתשובה ריקה.
async function readJsonResponse(response) {
  try {
    return await response.json();
  } catch {
    return null;
  }
}

// שולח משחק חדש לשירות ומרענן את ההיסטוריה לאחר הצלחה.
async function submitMatch() {
  clearFormError();
  resetFormHelp();

  const invalidField = elements.matchForm.querySelector(
    "input:invalid, textarea:invalid",
  );

  if (invalidField) {
    const label =
      invalidField.labels?.[0]?.textContent?.replace("*", "").trim() ||
      "a required field";

    showFormError(`Please complete or correct: ${label}.`);
    invalidField.focus();
    return;
  }

  let payload;

  try {
    payload = buildMatchPayload();
  } catch (error) {
    showFormError(error.message);
    return;
  }

  setSavingState(true);

  try {
    const response = await fetch(matchesApiPath, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const responsePayload = await readJsonResponse(response);

    if (!response.ok) {
      throw new Error(getErrorMessage(responsePayload));
    }

    elements.matchForm.reset();
    updateNotesCounter();
    showFormSuccess("Match saved successfully.");
    showToast("Your match was saved.");
    await loadMatches();
  } catch (error) {
    console.error(error);
    showFormError(error.message || "We could not save the match. Please try again.");
  } finally {
    setSavingState(false);
  }
}

// מציג שגיאה בתוך חלון המחיקה.
function showDeleteError(message) {
  elements.deleteDialogError.textContent = message;
  elements.deleteDialogError.hidden = false;
}

// מסתיר שגיאה קודמת מתוך חלון המחיקה.
function clearDeleteError() {
  elements.deleteDialogError.textContent = "";
  elements.deleteDialogError.hidden = true;
}

// משנה את מצב כפתורי המחיקה בזמן שהבקשה נשלחת.
function setDeleteState(isDeleting) {
  elements.cancelDeleteButton.disabled = isDeleting;
  elements.confirmDeleteButton.disabled = isDeleting;
  elements.confirmDeleteButton.textContent = isDeleting
    ? "Deleting..."
    : "Delete match";
}

// פותח חלון אישור עבור המשחק שנבחר.
function handleMatchListClick(event) {
  const target = event.target;

  if (!(target instanceof Element)) {
    return;
  }

  const deleteButton = target.closest("[data-delete-match]");

  if (!(deleteButton instanceof HTMLButtonElement)) {
    return;
  }

  const matchId = deleteButton.dataset.matchId;

  if (!matchId) {
    return;
  }

  const matchDescription =
    deleteButton.dataset.matchDescription || "this match";

  pendingDeletionMatchId = matchId;
  clearDeleteError();

  elements.deleteDialogMessage.textContent =
    `Delete ${matchDescription}? This action cannot be undone.`;

  elements.deleteDialog.showModal();
}

// מוחק את המשחק לאחר אישור מפורש של המשתמש.
async function deletePendingMatch() {
  if (!pendingDeletionMatchId) {
    return;
  }

  const matchId = pendingDeletionMatchId;

  clearDeleteError();
  setDeleteState(true);

  try {
    const response = await fetch(`${matchesApiPath}/${matchId}`, {
      method: "DELETE",
    });

    const responsePayload = await readJsonResponse(response);

    if (!response.ok) {
      throw new Error(getErrorMessage(responsePayload));
    }

    elements.deleteDialog.close();
    showToast("Match deleted successfully.");
    await loadMatches();
  } catch (error) {
    console.error(error);
    showDeleteError(
      error.message || "We could not delete the match. Please try again.",
    );
  } finally {
    setDeleteState(false);
  }
}

// מנקה את מצב המחיקה לאחר סגירת חלון האישור.
function resetDeleteDialog() {
  pendingDeletionMatchId = null;
  clearDeleteError();
  setDeleteState(false);
}

// תופס את שליחת הטופס לפני פעולת הניווט הרגילה של הדפדפן.
function handleMatchFormSubmit(event) {
  const submittedForm = event.target;

  if (!(submittedForm instanceof HTMLFormElement)) {
    return;
  }

  if (submittedForm.id !== "match-form") {
    return;
  }

  event.preventDefault();
  submitMatch();
}

// מחבר את כפתור הרענון לקריאת המשחקים.
elements.refreshButton.addEventListener("click", loadMatches);

// מחבר את מונה ההערות לשינויי המשתמש.
elements.notes.addEventListener("input", updateNotesCounter);

// מחבר פעולת לחיצה על כפתורי המחיקה בכרטיסי המשחקים.
elements.matchesList.addEventListener("click", handleMatchListClick);

// מחבר את אישור המחיקה לשליחת בקשת DELETE.
elements.confirmDeleteButton.addEventListener("click", deletePendingMatch);

// מנקה מידע זמני כאשר חלון המחיקה נסגר.
elements.deleteDialog.addEventListener("close", resetDeleteDialog);

// תופס את שליחת הטופס לפני שהיא מגיעה לפעולה הרגילה של הדפדפן.
document.addEventListener("submit", handleMatchFormSubmit, true);

// מציג את מונה ההערות ומטעין משחקים מיד לאחר פתיחת העמוד.
updateNotesCounter();
loadMatches();
