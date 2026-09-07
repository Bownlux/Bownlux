const username = "Bownlux";
const repoList = document.getElementById("repo-list");
const repoStatus = document.getElementById("repo-status");

async function loadRepos() {
  try {
    const response = await fetch(
      `https://api.github.com/users/${username}/repos?per_page=100&sort=updated`
    );

    if (!response.ok) {
      throw new Error(`GitHub API request failed: ${response.status}`);
    }

    const repos = await response.json();

    if (!Array.isArray(repos) || repos.length === 0) {
      repoStatus.textContent = "No public repositories found.";
      return;
    }

    repoStatus.textContent = `Showing ${repos.length} public repositories.`;
    repos.forEach((repo) => {
      const li = document.createElement("li");
      const text = repo.description ? ` — ${repo.description}` : "";
      li.innerHTML = `<a href="${repo.html_url}" target="_blank" rel="noreferrer">${repo.name}</a>${text}`;
      repoList.appendChild(li);
    });
  } catch (error) {
    repoStatus.textContent = "Could not load repositories right now.";
    console.error(error);
  }
}

loadRepos();
