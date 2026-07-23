import './globals.css';
export const metadata = { title: 'YohPal Admin Web', description: 'YohPal Live v2 admin console' };
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="en"><body>{children}</body></html>;
}
