/*
  Copyright 2024 The Outline Authors
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
       http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import {LitElement, html, css} from 'lit';
import {customElement, property, state} from 'lit/decorators.js';
import '@material/web/all.js';

@customElement('server-rename-dialog')
export class ServerRenameDialog extends LitElement {
  @property({type: Boolean}) open: boolean = false;
  @property({type: Function}) localize!: (key: string) => string;
  @property({type: String}) serverId!: string;
  @property({type: String}) serverName!: string;

  @state() private editedServerName: string | null = null;

  static styles = css`
    :host {
      --md-sys-color-primary: var(--outline-primary);
      --md-sys-shape-corner-extra-large: 2px;
      --md-sys-shape-corner-full: 2px;
    }

    fieldset {
      border: none;
      text-transform: uppercase;
    }
  `;

  render() {
    if (this.editedServerName === null) {
      this.editedServerName = this.serverName;
    }

    return html`
      <md-dialog .open="${this.open}" @close=${this.handleCancel} quick>
        <header slot="headline">${this.localize('server-rename')}</header>
        <md-filled-text-field
          slot="content"
          maxlength="100"
          value="${this.editedServerName}"
        ></md-filled-text-field>
        <fieldset slot="actions">
          <md-text-button @click="${this.handleCancel}"
            >${this.localize('cancel')}</md-text-button
          >
          <md-filled-button
            @click="${this.handleRename}"
            ?disabled="${this.editedServerName === this.serverName}"
            >${this.localize('save')}</md-filled-button
          >
        </fieldset>
      </md-dialog>
    `;
  }

  private handleCancel() {
    this.dispatchEvent(new CustomEvent('cancel'));

    this.editedServerName = null;
  }

  private handleRename() {
    this.dispatchEvent(
      new CustomEvent('submit', {
        detail: {id: this.serverId, name: this.editedServerName},
      })
    );

    this.editedServerName = null;
  }
}
