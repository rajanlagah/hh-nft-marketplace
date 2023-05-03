import { MoralisProvider } from "react-moralis";

import "@/styles/globals.css";
import Headers from "@/components/Headers";

export default function App({ Component, pageProps }) {
    return (
        <MoralisProvider initializeOnMount={false}>
            <Headers/>
            <Component {...pageProps} />
        </MoralisProvider>
    );
}
