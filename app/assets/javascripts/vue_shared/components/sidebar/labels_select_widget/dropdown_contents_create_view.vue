<script>
import { GlTooltipDirective, GlButton, GlFormInput, GlLink, GlLoadingIcon } from '@gitlab/ui';
import produce from 'immer';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { __ } from '~/locale';
import { labelsQueries } from '~/sidebar/constants';
import createLabelMutation from './graphql/create_label.mutation.graphql';

const errorMessage = __('Error creating label.');

export default {
  components: {
    GlButton,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  props: {
    issuableType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      labelTitle: '',
      selectedColor: '',
      labelCreateInProgress: false,
    };
  },
  computed: {
    disableCreate() {
      return !this.labelTitle.length || !this.selectedColor.length || this.labelCreateInProgress;
    },
    suggestedColors() {
      const colorsMap = gon.suggested_label_colors;
      return Object.keys(colorsMap).map((color) => ({ [color]: colorsMap[color] }));
    },
    mutationVariables() {
      return this.issuableType === IssuableType.Epic
        ? {
            title: this.labelTitle,
            color: this.selectedColor,
            groupPath: this.fullPath,
          }
        : {
            title: this.labelTitle,
            color: this.selectedColor,
            projectPath: this.fullPath,
          };
    },
  },
  methods: {
    getColorCode(color) {
      return Object.keys(color).pop();
    },
    getColorName(color) {
      return Object.values(color).pop();
    },
    handleColorClick(color) {
      this.selectedColor = this.getColorCode(color);
    },
    updateLabelsInCache(store, label) {
      const sourceData = store.readQuery({
        query: labelsQueries[this.issuableType].workspaceQuery,
        variables: { fullPath: this.fullPath, searchTerm: '' },
      });

      const collator = new Intl.Collator('en');
      const data = produce(sourceData, (draftData) => {
        const { nodes } = draftData.workspace.labels;
        nodes.push(label);
        nodes.sort((a, b) => collator.compare(a.title, b.title));
      });

      store.writeQuery({
        query: labelsQueries[this.issuableType].workspaceQuery,
        variables: { fullPath: this.fullPath, searchTerm: '' },
        data,
      });
    },
    async createLabel() {
      this.labelCreateInProgress = true;
      try {
        const {
          data: { labelCreate },
        } = await this.$apollo.mutate({
          mutation: createLabelMutation,
          variables: this.mutationVariables,
          update: (
            store,
            {
              data: {
                labelCreate: { label },
              },
            },
          ) => this.updateLabelsInCache(store, label),
        });
        if (labelCreate.errors.length) {
          createFlash({ message: errorMessage });
        }
      } catch {
        createFlash({ message: errorMessage });
      }
      this.labelCreateInProgress = false;
      this.$emit('hideCreateView');
    },
  },
};
</script>

<template>
  <div class="labels-select-contents-create js-labels-create">
    <div class="dropdown-input">
      <gl-form-input
        v-model.trim="labelTitle"
        :placeholder="__('Name new label')"
        :autofocus="true"
        data-testid="label-title-input"
      />
    </div>
    <div class="dropdown-content gl-px-3">
      <div class="suggest-colors suggest-colors-dropdown gl-mt-0! gl-mb-3!">
        <gl-link
          v-for="(color, index) in suggestedColors"
          :key="index"
          v-gl-tooltip:tooltipcontainer
          :style="{ backgroundColor: getColorCode(color) }"
          :title="getColorName(color)"
          @click.prevent="handleColorClick(color)"
        />
      </div>
      <div class="color-input-container gl-display-flex">
        <span
          class="dropdown-label-color-preview gl-relative gl-display-inline-block"
          data-testid="selected-color"
          :style="{ backgroundColor: selectedColor }"
        ></span>
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
          :placeholder="__('Use custom color #FF0000')"
          data-testid="selected-color-text"
        />
      </div>
    </div>
    <div class="dropdown-actions gl-display-flex gl-justify-content-space-between gl-pt-3 gl-px-3">
      <gl-button
        :disabled="disableCreate"
        category="primary"
        variant="success"
        class="gl-display-flex gl-align-items-center"
        data-testid="create-button"
        @click="createLabel"
      >
        <gl-loading-icon v-if="labelCreateInProgress" size="sm" :inline="true" class="mr-1" />
        {{ __('Create') }}
      </gl-button>
      <gl-button
        class="js-btn-cancel-create"
        data-testid="cancel-button"
        @click="$emit('hideCreateView')"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
