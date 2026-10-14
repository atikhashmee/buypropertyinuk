// Lender eligibility, from the brochure (Sept 2020). ponytail: hardcoded lists, move to a CMS/API when lenders change often.
const COUNTRIES = "Afghanistan|Albania|Algeria|Andorra|Angola|Antigua and Barbuda|Argentina|Armenia|Australia|Austria|Azerbaijan|Bahamas|Bahrain|Bangladesh|Barbados|Belarus|Belgium|Belize|Benin|Bhutan|Bolivia|Bosnia and Herzegovina|Botswana|Brazil|Brunei|Bulgaria|Burkina Faso|Burundi|Cambodia|Cameroon|Canada|Cape Verde|Central African Republic|Chad|Chile|China|Colombia|Comoros|Congo|Costa Rica|Croatia|Cuba|Cyprus|Czech Republic|Democratic Republic of the Congo|Denmark|Djibouti|Dominica|Dominican Republic|Ecuador|Egypt|El Salvador|Equatorial Guinea|Eritrea|Estonia|Eswatini|Ethiopia|Fiji|Finland|France|Gabon|Gambia|Georgia|Germany|Ghana|Greece|Grenada|Guatemala|Guinea|Guinea-Bissau|Guyana|Haiti|Honduras|Hong Kong|Hungary|Iceland|India|Indonesia|Iran|Iraq|Ireland|Israel|Italy|Ivory Coast|Jamaica|Japan|Jordan|Kazakhstan|Kenya|Kiribati|Kosovo|Kuwait|Kyrgyzstan|Laos|Latvia|Lebanon|Lesotho|Liberia|Libya|Liechtenstein|Lithuania|Luxembourg|Madagascar|Malawi|Malaysia|Maldives|Mali|Malta|Marshall Islands|Mauritania|Mauritius|Mexico|Micronesia|Moldova|Monaco|Mongolia|Montenegro|Morocco|Mozambique|Myanmar|Namibia|Nauru|Nepal|Netherlands|New Zealand|Nicaragua|Niger|Nigeria|North Korea|North Macedonia|Norway|Oman|Pakistan|Palau|Palestine|Panama|Papua New Guinea|Paraguay|Peru|Philippines|Poland|Portugal|Qatar|Romania|Russia|Rwanda|Saint Kitts and Nevis|Saint Lucia|Saint Vincent and the Grenadines|Samoa|San Marino|Sao Tome and Principe|Saudi Arabia|Senegal|Serbia|Seychelles|Sierra Leone|Singapore|Slovakia|Slovenia|Solomon Islands|Somalia|South Africa|South Korea|South Sudan|Spain|Sri Lanka|Sudan|Suriname|Sweden|Switzerland|Syria|Taiwan|Tajikistan|Tanzania|Thailand|Timor-Leste|Togo|Tonga|Trinidad and Tobago|Tunisia|Turkey|Turkmenistan|Tuvalu|Uganda|Ukraine|United Arab Emirates|United States|Uruguay|Uzbekistan|Vanuatu|Vatican City|Venezuela|Vietnam|Yemen|Zambia|Zimbabwe".split("|");

const set = s => new Set(s.split("|"));
const LENDER_A_EXCLUDED = set("Afghanistan|Argentina|Azerbaijan|Belarus|Myanmar|Cuba|Iran|Iraq|Kazakhstan|Lebanon|Liberia|Libya|Nigeria|North Korea|Russia|Sudan|Syria|Tajikistan|Tunisia|Turkmenistan|Ukraine|Uzbekistan|Venezuela|Yemen|Zimbabwe");
const LENDER_B_EXCLUDED = set("Afghanistan|Albania|Algeria|Angola|Argentina|Armenia|Australia|Azerbaijan|Bahamas|Bangladesh|Barbados|Belarus|Belize|Benin|Bolivia|Bosnia and Herzegovina|Botswana|Burkina Faso|Burundi|Cambodia|Cameroon|Cape Verde|Central African Republic|Chad|China|Comoros|Cuba|Democratic Republic of the Congo|Djibouti|Dominican Republic|Ecuador|Egypt|Equatorial Guinea|Eritrea|Ethiopia|Gabon|Gambia|Georgia|Ghana|Guatemala|Guinea-Bissau|Guinea|Guyana|Haiti|Honduras|Indonesia|Iran|Iraq|Ivory Coast|Jamaica|Kazakhstan|Kenya|Kiribati|North Korea|Kosovo|Kyrgyzstan|Laos|Lebanon|Lesotho|Liberia|Libya|Madagascar|Malawi|Maldives|Mali|Marshall Islands|Mauritania|Mauritius|Mexico|Moldova|Mongolia|Morocco|Mozambique|Myanmar|Namibia|Nepal|Nicaragua|Niger|Nigeria|Pakistan|Palau|Palestine|Panama|Papua New Guinea|Paraguay|Russia|Rwanda|Sao Tome and Principe|Senegal|Serbia|Seychelles|Sierra Leone|Solomon Islands|Somalia|South Sudan|Sri Lanka|Sudan|Eswatini|Syria|Tajikistan|Tanzania|Timor-Leste|Togo|Trinidad and Tobago|Tunisia|Turkmenistan|Uganda|Ukraine|Uzbekistan|Vanuatu|Venezuela|Vietnam|Yemen|Zambia|Zimbabwe");
const GCC = set("United Arab Emirates|Saudi Arabia|Qatar|Kuwait|Bahrain|Oman");

const FEE_TOTAL = 5250; // £250 assessment + £2,500 at DIP + £2,500 at offer
const gbp = n => "£" + Math.round(n).toLocaleString("en-GB");

document.getElementById("countries").innerHTML = COUNTRIES.map(c => `<option value="${c}">`).join("");
document.getElementById("year").textContent = new Date().getFullYear();

const $country = document.getElementById("country");
const $price = document.getElementById("price");
const $sourcing = document.getElementById("sourcing");
const $result = document.getElementById("result");

function render() {
  const name = COUNTRIES.find(c => c.toLowerCase() === $country.value.trim().toLowerCase());
  const price = Number($price.value.replace(/[^\d]/g, ""));

  if (!name) {
    $result.innerHTML = `<p class="empty">${$country.value.trim()
      ? "Choose a country from the list to see your options."
      : "Enter your country to see which lenders will consider you."}</p>`;
    return;
  }

  const lenders = [
    ["Lender A, buy to let", !LENDER_A_EXCLUDED.has(name)],
    ["Lender B, buy to let", !LENDER_B_EXCLUDED.has(name)],
  ];
  if (GCC.has(name)) lenders.unshift(["Islamic finance, Commodity Murabaha", true]);
  const any = lenders.some(([, ok]) => ok);

  let html = `<p class="result-title">${any ? `Residents of ${name} can apply.` : `Our lenders do not currently accept residents of ${name}.`}</p>
    <ul class="lenders">${lenders.map(([l, ok]) =>
      `<li><span>${l}</span><span class="${ok ? "yes" : "no"}">${ok ? "Will consider you" : "Not available"}</span></li>`).join("")}</ul>`;

  if (any && price > 0) {
    const sourcing = $sourcing.checked ? price * 0.005 : 0;
    html += `<dl class="sums">
      <div><dt>Your deposit, 25%</dt><dd>${gbp(price * 0.25)}</dd></div>
      <div><dt>Mortgage, up to 75%</dt><dd>${gbp(price * 0.75)}</dd></div>
      <div><dt>Our fee, in three stages</dt><dd>${gbp(FEE_TOTAL)}</dd></div>
      ${sourcing ? `<div><dt>Property sourcing, 0.5%</dt><dd>${gbp(sourcing)}</dd></div>` : ""}
    </dl>`;
    if (GCC.has(name) && price * 0.75 < 100000) html += `<p class="result-note">Islamic finance starts at £100,000 of finance, so a price of at least ${gbp(100000 / 0.75)} is needed.</p>`;
  }

  html += `<p class="result-note">${any
    ? "The amount you can borrow depends on the expected rent and lender checks. Solicitor, valuation and stamp duty are separate."
    : `If you are a national of ${name} but live permanently elsewhere, choose the country you live in instead.`}</p>`;

  $result.innerHTML = html;
}

$price.addEventListener("input", () => {
  const n = $price.value.replace(/[^\d]/g, "");
  $price.value = n ? Number(n).toLocaleString("en-GB") : "";
  render();
});
$country.addEventListener("input", render);
$sourcing.addEventListener("change", render);

// No backend yet: confirm locally. ponytail: wire to a form service or API once the client provides a server.
document.getElementById("enquiry").addEventListener("submit", e => {
  e.preventDefault();
  const form = e.target;
  if (!form.reportValidity()) return;
  document.getElementById("form-status").textContent = `Thank you, ${form.first.value}. Your enquiry has been sent and an adviser will be in touch.`;
  form.reset();
});
