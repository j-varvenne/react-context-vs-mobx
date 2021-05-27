import { FC, createContext, useState, useContext } from "react";


const storeContext = createContext<StoreContext | null>(null);

const Provider: FC<{ value: StoreContext }> = ({ value, children }) => (
    <storeContext.Provider value={value}>{children}</storeContext.Provider>
);

export const App: FC<{}> = () => {
    const [state, setState] = useState("fooar");
    const [store, setStore] = useState({
        test: "abc"
    });
    console.log("RENDERING APP");

    return (
        <Provider value={{ store, setStore }}>
            <div>
                <h1>Hello from AppContext</h1>
                <input value={state} onChange={(ev) => setState(ev.target.value)} />
                <Comp1 />
                <Comp2 id="branch 2" />
            </div>
        </Provider>
    );
}

const Comp1 = () => {
    const { store } = useContext(storeContext) as StoreContext;
    return (
        <div>
            {(console.log("RENDERING Comp1"), null)}
            value: {store.test}
            <Comp2 id="branch 1" />
        </div>
    );
};

const Comp2: FC<{ id: string }> = ({ id }) => (
    <div>
        {(console.log("RENDERING Comp2 " + id), null)}
        <Comp3 id={id} />
    </div>
);

const Comp3: FC<{ id: string }> = ({ id }) => {
    const { store, setStore } = useContext(storeContext) as StoreContext;
    return (
        <div>
            {(console.log("RENDERING Comp3 " + id), null)}
            <input
                value={store.test}
                onChange={(ev) => setStore({ test: ev.target.value })}
            />
        </div>
    );
};


interface StoreContext {
    store: Store
    setStore: (val: Store) => void
}

interface Store {
    test: string
}