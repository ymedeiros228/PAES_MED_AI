// Login do PAES MED AI (Vercel Routing Middleware: roda antes do cache e de tudo).
// O app em si (tela de entrada) abre para qualquer um; a API e os arquivos de /data
// (provas, PDFs, figuras) só com a sessão criada no login: cookie paes_sessao, assinado
// pelo backend/auth.py com PAES_SESSAO_SEGREDO. As rotas /api/auth/* ficam livres.
export const config = { matcher: ["/api/:path*", "/data/:path*"] };

const COOKIE = "paes_sessao";

function base64url(bytes) {
  let texto = "";
  for (const b of new Uint8Array(bytes)) texto += String.fromCharCode(b);
  return btoa(texto).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function lerCookie(request, nome) {
  for (const parte of (request.headers.get("cookie") || "").split(";")) {
    const i = parte.indexOf("=");
    if (i > 0 && parte.slice(0, i).trim() === nome) return parte.slice(i + 1).trim();
  }
  return "";
}

async function sessaoValida(token, segredo) {
  const [corpo, assinatura] = token.split(".");
  if (!corpo || !assinatura) return false;
  const chave = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(segredo),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const esperada = base64url(await crypto.subtle.sign("HMAC", chave, new TextEncoder().encode(corpo)));
  if (esperada.length !== assinatura.length) return false;
  let diferenca = 0;
  for (let i = 0; i < esperada.length; i++) diferenca |= esperada.charCodeAt(i) ^ assinatura.charCodeAt(i);
  if (diferenca !== 0) return false;
  try {
    const dados = JSON.parse(atob(corpo.replace(/-/g, "+").replace(/_/g, "/")));
    return typeof dados.exp === "number" && dados.exp > Date.now() / 1000;
  } catch {
    return false;
  }
}

function json(status, detail) {
  return new Response(JSON.stringify({ detail }), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" },
  });
}

export default async function middleware(request) {
  if (new URL(request.url).pathname.startsWith("/api/auth/")) return;
  const segredo = process.env.PAES_SESSAO_SEGREDO;
  if (!segredo) return json(503, "Login não configurado no servidor (PAES_SESSAO_SEGREDO).");
  if (await sessaoValida(lerCookie(request, COOKIE), segredo)) return;
  return json(401, "Faça login para continuar.");
}
