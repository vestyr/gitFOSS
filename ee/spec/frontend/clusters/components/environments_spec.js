import { createLocalVue, mount } from '@vue/test-utils';
import Environments from 'ee/clusters/components/environments.vue';
import { GlTable, GlEmptyState } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import environments from './mock_data';

const localVue = createLocalVue();

describe('Environments', () => {
  const Component = localVue.extend(Environments);
  let wrapper;
  let propsData;

  beforeEach(() => {
    propsData = {
      environments: [],
      environmentsHelpPath: 'path/to/environments',
      clustersHelpPath: 'path/to/clusters',
      deployBoardsHelpPath: 'path/to/clusters',
      isFetching: false,
    };

    wrapper = mount(Component, {
      propsData,
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an empty state if no deployments are found', () => {
    const emptyState = wrapper.find(GlEmptyState);
    const emptyStateText =
      'No deployments found Ensure your environment is part of the deploy stage of your CI pipeline to track deployments to your cluster. Learn more about deploying to a cluster';

    expect(emptyState.exists()).toBe(true);
    expect(emptyState.text()).toEqual(emptyStateText);
  });

  describe('environments table', () => {
    let table;

    beforeAll(() => {
      wrapper = mount(Component, {
        propsData: { ...propsData, environments },
        localVue,
        stubs: { deploymentInstance: '<div class="js-deployment-instance"></div>' },
        sync: false,
      });

      table = wrapper.find(GlTable);
    });

    it('renders a table component', () => {
      expect(table.exists()).toBe(true);
    });

    it('renders the correct table headers', () => {
      const tableHeaders = ['Project', 'Environment', 'Job', 'Pods in use 3', 'Last updated'];
      const headers = table.findAll('th');

      expect(headers.length).toBe(tableHeaders.length);

      tableHeaders.forEach((headerText, i) => expect(headers.at(i).text()).toEqual(headerText));
    });

    describe('deployment instances', () => {
      let tableRows;

      beforeAll(() => {
        tableRows = table.findAll('tbody tr');
      });

      it('renders deployment instances', () => {
        environments.forEach((environment, i) => {
          const { instances } = environment.rolloutStatus;

          expect(tableRows.at(i).findAll('.js-deployment-instance').length).toBe(instances.length);
        });
      });

      it('renders an empty state if no deployment instances are found', () => {
        const emptyStateText =
          'Deploy progress not found. To see pods, ensure your environment matches deploy board criteria.';

        environments.forEach((environment, i) => {
          const { instances } = environment.rolloutStatus;

          if (instances.length === 0) {
            const emptyState = tableRows.at(i).find('.deployments-empty');
            const emptyStateIcon = emptyState.find(Icon);

            expect(emptyState.exists()).toBe(true);
            expect(emptyStateIcon.exists()).toBe(true);
            expect(emptyState.text()).toEqual(emptyStateText);
            expect(emptyStateIcon.props().name).toEqual('warning');
          }
        });
      });
    });
  });
});