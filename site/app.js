const LINK_LABELS = {
  github: "GitHub",
  demo: "Demo",
  posit: "Posit",
  myDeployment: "My Deployment",
  doi: "DOI",
  docs: "Docs",
  cran: "CRAN",
  pypi: "PyPI",
  npm: "npm",
  runiverse: "R-universe",
  small: "Thumb (small)",
  large: "Thumb (large)",
};

const LINK_ORDER = [
  "github",
  "demo",
  "posit",
  "myDeployment",
  "doi",
  "docs",
  "cran",
  "pypi",
  "npm",
  "runiverse",
  "small",
  "large",
];

function linkList(links) {
  const el = document.createElement("div");
  el.className = "linklist";
  LINK_ORDER.filter((key) => links[key]).forEach((key) => {
    const a = document.createElement("a");
    a.href = links[key];
    a.textContent = LINK_LABELS[key];
    a.className = key;
    a.target = "_blank";
    a.rel = "noopener";
    el.appendChild(a);
  });
  return el;
}

function thumbCell(smallSrc, largeSrc, alt, version) {
  const td = document.createElement("td");
  td.className = "thumb-cell";
  const a = document.createElement("a");
  a.href = largeSrc;
  a.target = "_blank";
  a.rel = "noopener";
  const img = document.createElement("img");
  img.src = smallSrc;
  img.alt = alt;
  img.loading = "lazy";
  a.appendChild(img);
  td.appendChild(a);
  if (version) {
    const v = document.createElement("span");
    v.className = "version";
    v.textContent = version;
    td.appendChild(v);
  }
  return td;
}

function appRow(app) {
  const tr = document.createElement("tr");

  tr.appendChild(thumbCell(app.thumbnail.small, app.thumbnail.large, app.title, app.version));

  const nameTd = document.createElement("td");
  nameTd.textContent = app.title;
  tr.appendChild(nameTd);

  const descTd = document.createElement("td");
  descTd.textContent = app.abstract;
  tr.appendChild(descTd);

  const linksTd = document.createElement("td");
  const links = { ...app.links, small: app.thumbnail.small, large: app.thumbnail.large };
  linksTd.appendChild(linkList(links));
  tr.appendChild(linksTd);

  return tr;
}

function packageRow(pkg) {
  const tr = document.createElement("tr");

  const logoTd = document.createElement("td");
  logoTd.className = "thumb-cell logo-cell";
  const img = document.createElement("img");
  img.src = pkg.logo;
  img.alt = pkg.title + " logo";
  img.loading = "lazy";
  logoTd.appendChild(img);
  tr.appendChild(logoTd);

  const nameTd = document.createElement("td");
  const strong = document.createElement("div");
  strong.textContent = pkg.title;
  const org = document.createElement("div");
  org.className = "org";
  org.textContent = pkg.org;
  nameTd.appendChild(strong);
  nameTd.appendChild(org);
  tr.appendChild(nameTd);

  const descTd = document.createElement("td");
  descTd.textContent = pkg.description;
  tr.appendChild(descTd);

  const linksTd = document.createElement("td");
  linksTd.appendChild(linkList(pkg.links || {}));
  tr.appendChild(linksTd);

  return tr;
}

async function loadTables() {
  const appsBody = document.querySelector("#apps-table tbody");
  const packagesBody = document.querySelector("#packages-table tbody");

  if (appsBody) {
    const apps = await fetch("data/apps.json", { cache: "no-store" }).then((r) => r.json());
    apps.forEach((app) => appsBody.appendChild(appRow(app)));
  }

  if (packagesBody) {
    const packages = await fetch("data/packages.json", { cache: "no-store" }).then((r) => r.json());
    packages.forEach((pkg) => packagesBody.appendChild(packageRow(pkg)));
  }
}

loadTables();
