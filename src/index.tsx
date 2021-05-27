import { render } from 'react-dom';

import { App as AppMobx } from './AppMobx';
import { App as AppContext } from './AppContext';
import { App as AppHybrid } from './AppHybrid';

render(
    <AppMobx />,
    document.getElementById("root-mobx"),
);
render(
    <AppContext />,
    document.getElementById("root-context"),
);
render(
    <AppHybrid />,
    document.getElementById("root-hybrid"),
);
