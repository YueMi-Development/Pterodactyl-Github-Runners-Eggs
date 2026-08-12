const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const eggPath = path.join(__dirname, '..', 'egg-github-runners.json');

try {
  // Read existing egg file
  const egg = JSON.parse(fs.readFileSync(eggPath, 'utf8'));

  // Update exported_at timestamp
  const now = new Date();
  egg.exported_at = now.toISOString();

  // Set update_url
  egg.meta.update_url = "https://raw.githubusercontent.com/YueMi-Development/Pterodactyl-Github-Runners-Eggs/main/egg-github-runners.json";

  // Get latest 5 tags from git
  let tags = [];
  try {
    const gitTagsOutput = execSync('git tag --sort=-v:refname').toString().trim();
    if (gitTagsOutput) {
      tags = gitTagsOutput.split('\n').filter(Boolean).slice(0, 5);
    }
  } catch (err) {
    console.warn('Failed to retrieve tags from git:', err.message);
  }

  // Build docker_images object
  const dockerImages = {
    "Latest": "ghcr.io/yuemi-development/pterodactyl-github-runners-eggs:main"
  };

  // Append up to 5 newest tag versions
  tags.forEach(tag => {
    dockerImages[tag] = `ghcr.io/yuemi-development/pterodactyl-github-runners-eggs:${tag}`;
  });

  egg.docker_images = dockerImages;

  // Write back to egg file
  fs.writeFileSync(eggPath, JSON.stringify(egg, null, 4) + '\n', 'utf8');
  console.log('Successfully updated egg-github-runners.json with latest tags and timestamp.');
} catch (error) {
  console.error('Error updating egg file:', error);
  process.exit(1);
}
