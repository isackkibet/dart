export default function WalletSessionPage({params}:{params:{sessionId:string}}) {
  return <main style={{padding:24}}><h1>YohPal Web Wallet</h1><p>Session: {params.sessionId}</p><button>Proceed Securely</button></main>;
}
