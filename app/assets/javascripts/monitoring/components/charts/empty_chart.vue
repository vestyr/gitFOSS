<script>
import chartEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg';
import { chartHeight } from '../../constants';

export default {
  data() {
    return {
      height: chartHeight,
    };
  },
  computed: {
    svgContainerStyle() {
      return {
        height: `${this.height}px`,
      };
    },
  },
  created() {
    this.chartEmptyStateIllustration = chartEmptyStateIllustration;
  },
};
</script>
<template>
  <div class="d-flex flex-column justify-content-center">
    <div
      class="gl-mt-3 svg-w-100 d-flex align-items-center"
      :style="svgContainerStyle"
      v-html="chartEmptyStateIllustration /* eslint-disable-line vue/no-v-html */"
    ></div>
    <h5 class="text-center gl-mt-3">{{ __('No data to display') }}</h5>
  </div>
</template>
