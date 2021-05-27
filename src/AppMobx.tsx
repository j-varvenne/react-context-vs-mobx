import { observable } from 'mobx';
import { observer } from 'mobx-react-lite';
import { FC, useState } from 'react';


const store = observable({
    test: "abc"
});

export const App: FC<{}> = ({ }) => {
    const [state, setState] = useState("fooar");

    console.log("RENDERING APP");

    return (
        <div>
            <h1>Hello from AppMobx</h1>
            <input value={state} onChange={(ev) => setState(ev.target.value)} />
            <Comp1 />
            <Comp2 id="branch 2" />
        </div>
    );
}

const Comp1 = observer(() => (
    <div>
        {(console.log("RENDERING Comp1"), null)}
        value: {store.test}
        <Comp2 id="branch 1" />
    </div>
));

const Comp2: FC<{ id: string }> = ({ id }) => (
    <div>
        {(console.log("RENDERING Comp2 " + id), null)}
        <Comp3 id={id} />
    </div>
);

const Comp3: FC<{ id: string }> = observer(({ id }) => (
    <div>
        {(console.log("RENDERING Comp3 " + id), null)}
        <input
            value={store.test}
            onChange={(ev) => (store.test = ev.target.value)}
        />
    </div>
));